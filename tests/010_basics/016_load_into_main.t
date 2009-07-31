#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
    plan tests => 2;
}

stderr_like( sub { package main; eval 'use Moose' },
             qr/\QMoose does not export its sugar to the 'main' package/,
             'Moose warns when loaded from the main package' );

stderr_like( sub { package main; eval 'use Moose::Role' },
             qr/\QMoose::Role does not export its sugar to the 'main' package/,
             'Moose::Role warns when loaded from the main package' );
