Text::TNetstrings
=================

The library provides an implementation of the TNetstrings serialization
format.


Usage
=====

	use Text::TNetstrings qw(:all);

	my $data = encode_tnetstrings({"foo" => "bar"}) # => "12:3:foo,3:bar,}"
	my $hash = decode_tnetstrings($data)            # => {"foo" => "bar"}

Performance
===========

The JSON benchmark shows that TNetstrings is about twice as fast as the
Pure-Perl JSON module (version 2.27105).

	$ perl -Ilib benchmark/json.pl
	               Rate    JSON::PP TNetstrings    JSON::XS
	JSON::PP      694/s          --        -32%        -97%
	TNetstrings  1017/s         46%          --        -96%
	JSON::XS    27248/s       3824%       2578%          --

Similarly the Pure-Perl version of Data::Dumper performs about twice as
slow as TNetstrings.

	$ perl -Ilib benchmark/dumper.pl
	              Rate      Dumper TNetstrings
	Dumper       690/s          --        -36%
	TNetstrings 1080/s         56%          --


Installation
============

Module::Build is used as the build system for this library. The typical
procedure applies:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


Documentation
=============

The library contains embedded POD documentation. Any of the POD tools
can be used to generate documentation, such as pod2html


License
=======

The library is licensed under the MIT license. Please read the LICENSE
file for details.


