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
Pure-Perl JSON module (version 2.27105), and the XS version is 50%
slower than the JSON module.

	$ perl -Ilib benchmark/json.pl
	                   Rate     JSON::PP TNetstrings::PP TNetstrings::XS    JSON::XS
	JSON::PP          730/s           --            -47%            -96%        -98%
	TNetstrings::PP  1379/s          89%              --            -92%        -95%
	TNetstrings::XS 16584/s        2170%           1102%              --        -44%
	JSON::XS        29499/s        3938%           2039%             78%          --

The above benchmarks were performed on a dual core Intel Atom 330 @ 1.6GHz.


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


