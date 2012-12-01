#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Text::TNetstrings::Test;

$ENV{"PERL_ONLY"} = 1;
diag("Using pure-Perl version of Text::TNetstrings");
my $test = Text::TNetstrings::Test->new('package' => 'Text::TNetstrings::PP');
$test->runtests;

