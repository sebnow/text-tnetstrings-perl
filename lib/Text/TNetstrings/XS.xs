#include <math.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

const STRLEN INIT_SIZE = 32;

static STRLEN int_length(IV i);
static void tn_encode(SV *data, SV *encoded);

static void
tn_encode(SV *data, SV *encoded)
{
	SV *sv;
	HE *entry;
	I32 len;
	I32 i;

	/* Null */
	if(!SvOK(data)) {
		sv_catpv(encoded, "0:~");
	}
	/* Integer */
	else if(SvIOK(data)) {
		sv_catpvf(encoded, "%zu:%s#", SvCUR(data), SvPV_nolen(data));
	}
	/* Floating point */
	else if(SvNOK(data)) {
		sv_catpvf(encoded, "%zu:%s^", SvCUR(data), SvPV_nolen(data));
	}
	/* String */
	else if(SvPOK(data)) {
		sv_catpvf(encoded, "%zu:%s,", SvCUR(data), SvPV_nolen(data));
	}
	/* Reference (Hash/Array) */
	else if(SvROK(data)) {
		data = SvRV(data);
		switch(SvTYPE(data)) {
			case SVt_PVAV:
				len = av_len((AV *)data) + 1;
				sv = newSV(INIT_SIZE);
				sv_setpv(sv, "");
				for(i = 0; i < len; i++) {
					tn_encode(*av_fetch((AV *)data, i, 0), sv);
				}
				sv_catpvf(encoded, "%zu:%s]", SvCUR(sv), SvPV_nolen(sv));
				sv_free(sv);
				sv = NULL;
				break;
			case SVt_PVHV:
				hv_iterinit((HV *)data);
				sv = newSV(INIT_SIZE);
				sv_setpv(sv, "");
				while(entry = hv_iternext((HV *)data)) {
					SV *key = hv_iterkeysv(entry);
					SvPOK_on(key);
					tn_encode(key, sv);
					tn_encode(hv_iterval((HV *)data, entry), sv);
				}
				sv_catpvf(encoded, "%zu:%s}", SvCUR(sv), SvPV_nolen(sv));
				sv_free(sv);
				sv = NULL;
				break;
			default:
				croak("encountered %s (%s), but TNetstrings can only represent references to arrays or hashes",
					SvPV_nolen(data), sv_reftype(data, 0));
		}
	} else {
		croak("support for type (%s, %s) not implemented, please file a bug",
			sv_reftype(data, 0), SvPV_nolen(data));
	}
}

/* The tn_decode function will modify the input string to optimize
 * tokenization.
 *
 * The format of a TNetstring is <length>:<body><type_indicator>. To
 * avoid copying strings, the colon (':') delimiter and type indicator
 * are replaced with a NULL byte. This enables atoi(), strlen(), etc.
 * to work on the embedded strings.
 */
static SV *
tn_decode(char *encoded, char **rest)
{
	SV *decoded = NULL;;
	STRLEN byte_length = 0;
	STRLEN length = 0;
	char *cursor = encoded;
	char *end = NULL;
	char type;

	if(*cursor > '9' || '0' > *cursor) {
		croak("expected number but got \"%s\"", cursor);
	}

	/* Find the end of the length field */
	end = strchr(cursor, ':');
	if(end == NULL) {
		croak("expected ':'");
	}
	*end = '\0';
	byte_length = atoi(cursor);
	/* Find boundry of body */
	cursor = end + 1;
	length = strlen(cursor) - 1; /* Ignore type indicator */
	if(byte_length > length) {
		croak("expected %d bytes but got %d: \"%s\"", byte_length, length);
	}
	/* Find and terminate type indicator */
	end = cursor + byte_length;
	type = *end;
	*end = '\0';
	if(rest != NULL) {
		if(length > byte_length) {
			*rest = end + 1;
		} else {
			*rest = NULL;
		}
	}

	/* Everything in between is the body */
	switch(type) {
		case ']': /* Array */
			decoded = newRV_noinc((SV *)newAV());
			while(cursor != NULL && cursor <= end) {
				SV *elem = tn_decode(cursor, &cursor);
				if(elem != NULL) {
					av_push((AV *)SvRV(decoded), elem);
				} else {
					croak("expected array element but got \"%s\"", cursor);
				}
			}
			break;
		case '!': /* Boolean */
			if(strcmp(cursor, "true") == 0) {
				decoded = newSViv(1);
			} else if(strcmp(cursor, "false") == 0) {
				decoded = newSViv(0);
			} else {
				croak("expected \"true\" or \"false\" but got \"%s\"", cursor);
			}
			break;
		case '^': /* Float */
			decoded = newSVnv(atof(cursor));
			break;
		case '}': /* Hash */
			decoded = newRV_noinc((SV *)newHV()); // TODO
			while(cursor != NULL && cursor <= end) {
				SV *key = tn_decode(cursor, &cursor);
				if(key == NULL) {
					croak("expected hash key but got \"%s\"", cursor);
				} else if(SvROK(key)) {
					croak("hash keys must be strings");
				}
				SV *value = tn_decode(cursor, &cursor);
				if(value == NULL) {
					croak("expected hash value but got \"%s\"", cursor);
				}
				/* Hash takes ownership of value but not key. The value
				 * refcount must be decremented if storing fails. The
				 * key's refcount must always be decremented. */
				if(!hv_store_ent((HV *)SvRV(decoded), key, value, 0)) {
					SvREFCNT_dec(decoded);
				}
				SvREFCNT_dec(key);
			}
			break;
		case '~': /* Null */
			decoded = &PL_sv_undef;
			break;
		case '#': /* Number */
			decoded = newSViv(atoi(cursor));
			break;
		case ',': /* String */
			decoded = newSVpvn(cursor, end - cursor);
			break;
		default:
			croak("invalid date type '%c'", type);
	}
	return decoded;
}

/* XSUBS */
MODULE = Text::TNetstrings::XS PACKAGE = Text::TNetstrings::XS PREFIX=TN_

SV *
TN_encode_tnetstrings(data)
	SV *data
	PREINIT:
		SV *encoded = newSV(INIT_SIZE);
	CODE:
	{
		sv_setpv(encoded, "");
		SvPOK_only(encoded);
		tn_encode(data, encoded);
		RETVAL = encoded;
	}
	OUTPUT:
		RETVAL

SV *
TN_decode_tnetstrings(encoded)
	SV *encoded
	PREINIT:
		SV *sv = NULL;
		char *rest = NULL;
	PPCODE:
	{
		/* tn_decode modifies the input string, so give it a /copy/ of
		 * provided SV */
		sv = newSVsv(encoded);
		SvPOK_only(encoded);
		XPUSHs(sv_2mortal(tn_decode(SvPV_nolen(sv), &rest)));
		sv_free(sv);
		if(rest != NULL) {
			XPUSHs(sv_2mortal(newSVpvn(rest, strlen(rest))));
		}
	}
