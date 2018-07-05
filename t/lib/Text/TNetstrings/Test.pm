package Text::TNetstrings::Test;
use base qw(Test::Class);
use Encode qw(encode_utf8);
use Test::More;

sub test_use : Test(startup => 1) {
	my $self = shift;
	$self->{'package'} ||= 'Text::TNetstrings';
	use_ok($self->{'package'}, qw(encode_tnetstrings decode_tnetstrings))
		or $self->BAIL_OUT("unable to import $self->{package}");
}

sub test_encode_null : Tests(4) {
	my $null = undef;
	my $encoded = encode_tnetstrings($null);
	my $given = "Given a null value, when the null value is encoded, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, 0, $given .
		"then the length should be zero");
	is($data, '', $given .
		"then the data field should be empty");
	is($type, '~', $given .
		"then the type indicator should be '~'");
}

sub test_encode_boolean : Tests(4) {
	eval {require boolean} or return "boolean is not installed";

	my $boolean = boolean::true();
	my $encoded = encode_tnetstrings($boolean);
	my $given = "Given a boolean value, when the boolean value is true and encoded, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, 4, $given .
		"then the length should be 4");
	is($data, 'true', $given .
		"then the data field should be \"true\"");
	is($type, '!', $given .
		"then the type indicator should be '!'");
}

sub test_encode_string : Tests(4) {
	use utf8;
	my $string = "héllö";
	my $encoded = encode_tnetstrings($string);
	my $given = qq(Given a string "$string", when the string is encoded, );
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	use bytes;
	is($length, length($string), $given .
		"then the length should be " . length($string));
	is($data, encode_utf8($string), $given .
		"then the data field should be the same as the string");
	is($type, ',', $given .
		"then the type indicator should be ','");
}

sub test_encode_string_null : Tests(3) {
	my $string = "hel\0lo";
	my $encoded = encode_tnetstrings($string);
	my $given = qq(Given a string "$string", ) .
		"when the string is encoded, " .
		"and the string contains a NULL byte, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, length($string), $given .
		"then the length should be " . length($string));
	is($data, $string, $given .
		"then the data field should be the same as the string");
}

sub test_encode_integer : Tests(4) {
	my $number = 42;
	my $encoded = encode_tnetstrings($number);
	my $given = qq(Given an integer $number, when the integer is encoded, );
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, length($number), $given .
		"then the length should be " . length("$number"));
	is($data, $number, $given .
		"then the data field should be the same as the number");
	is($type, '#', $given .
		"then the type indicator should be '#'");
}

sub test_encode_float : Tests(4) {
	my $float = 3.14159265;
	my $encoded = encode_tnetstrings($float);
	my $given = qq(Given a float $float, when the float is encoded, );
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, length($float), $given .
		"then the length should be " . length("$float"));
	is($data, $float, $given .
		"then the data field should be the same as the float");
	is($type, '^', $given .
		"then the type indicator should be '^'");
}

sub test_encode_array : Tests(4) {
	my $array = ["hello", 42];
	my $encoded = encode_tnetstrings($array);
	my $given = "Given a flat array [" . join(', ', @$array) . "], when the array is encoded, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $encoded_elements = join('', map {encode_tnetstrings($_)} @$array);
	is($length, length($encoded_elements), $given .
		"then the length should be equal to the length of its elements");
	is($data, $encoded_elements, $given .
		"then the data field should contain the encoded elements of the array");
	is($type, ']', $given .
		"then the type indicator should be ']'");
}

sub test_encode_hash : Tests(4) {
	my $hash = {"hello" => 42};
	my $encoded = encode_tnetstrings($hash);
	my $hash_str = join(', ', map {"$_: " . $hash->{$_}} keys(%$hash));
	my $given = "Given a flat hash [$hash_str], when the hash is encoded, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $encoded_elements = '';
	while(my ($key, $value) = each(%$hash)) {
		$encoded_elements .= encode_tnetstrings($key);
		$encoded_elements .= encode_tnetstrings($value);
	}
	is($length, length($encoded_elements), $given .
		"then the length should be equal to the length of its elements");
	is($data, $encoded_elements, $given .
		"then the data field should contain the encoded pairs of the hash");
	is($type, '}', $given .
		"then the type indicator should be '}'");
}

sub test_decode_null : Tests(1) {
	my $encoded = "0:~";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	is($decoded, undef,
		"Given an encoded TNetstring, " .
		"and the TNetstring contains a null value, " .
		"when the null value is decoded, " .
		"then the decoded value should be undefined");
}

sub test_decode_string : Tests(2) {
	my $encoded = "5:hello,";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the string \"hello\", " .
		"when the string is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, "hello", $given .
		"then the decoded value should be the string \"hello\"");
}

sub test_decode_string_null : Tests(2) {
	my $encoded = "6:he\0llo,";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the string, " .
		"and the string contains a null byte, " .
		"when the string is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, $data, $given .
		"then the null byte should not be processed in any special way");
}

sub test_decode_integer : Tests(2){
	my $encoded = "2:42#";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the integer 42, " .
		"when the integer is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, 42, $given .
		"then the decoded value should be the integer 42");
}

sub test_decode_integer_negative : Tests(2) {
	my $encoded = "3:-42#";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the negative integer -42, " .
		"when the integer is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, -42, $given .
		"then the decoded value should be the negative integer -42");
}

sub test_decode_float : Tests(2) {
	my $encoded = "10:3.14159265^";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the float 3.14159265, " .
		"when the float is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is("$decoded", "3.14159265", $given .
		"then the decoded value should be the float 3.14159265");
}

sub test_decode_float_negative : Tests(2) {
	my $encoded = "11:-3.14159265^";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the negative float -3.14159265, " .
		"when the float is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is("$decoded", "-3.14159265", $given .
		"then the decoded value should be the negative float -3.14159265");
}

sub test_decode_boolean_true : Tests(2) {
	my $encoded = "4:true!";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the boolean true, " .
		"when the boolean is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	ok($decoded, $given .
		"then the decoded value should be boolean true");
}

sub test_decode_boolean_false : Tests(2) {
	my $encoded = "5:false!";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the boolean false, " .
		"when the boolean is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	ok(!$decoded, $given .
		"then the decoded value should be boolean false");
}

sub test_decode_array : Tests(2) {
	my $encoded = "18:2:32#2:84#5:hello,]";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the array [32, 84, \"hello\"], " .
		"when the array is decoded, ";
	is(ref($decoded), 'ARRAY', $given .
		"then the decoded value should be an array");
	is_deeply($decoded, [32, 84, "hello"], $given .
		"then the decoded value should be the array [32, 84, \"hello\"]");
}

sub test_decode_hash : Tests(2) {
	my $encoded = "16:1:a,1:1#1:b,1:2#}";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the hash {a => 1, b => 2}, " .
		"when the hash is decoded, ";
	is(ref($decoded), 'HASH', $given .
		"then the decoded value should be a hash");
	is_deeply($decoded, {"a" => 1, "b" => 2}, $given .
		"then the decoded value should be the hash {a => 1, b => 2}");
}

sub test_decode_string_rest : Tests(3) {
	my $encoded = "5:hello,other irrelevant text";
	my ($decoded, $rest) = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the string \"hello\", " .
		"and other data follows the TNetstring, " .
		"when the string is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, "hello", $given .
		"then the decoded value should be the string \"hello\"");
	is($rest, "other irrelevant text", $given .
		"then the remaining data should be returned");
}

1;

