#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Text::TNetstrings::Test;

$ENV{"TNETSTRINGS_XS"} = 1;
diag("Using XS version of Text::TNetstrings");
my $test = Text::TNetstrings::Test->new('package' => 'Text::TNetstrings::XS');

eval {
	require Text::TNetstrings::XS
} or plan skip_all => 'unable to import Text::TNetstrings::XS';
$test->runtests;

