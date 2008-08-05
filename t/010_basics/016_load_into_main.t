#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
    plan tests => 1;
}

stderr_is( sub { package main; eval 'use Moose' },
           "Moose does not export its sugar to the 'main' package.\n",
           'Moose warns when loaded from the main package' );
