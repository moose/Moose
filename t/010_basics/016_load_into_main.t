#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Output;

stderr_is( sub { package main; eval 'use Moose' },
           "Moose does not export its sugar to the 'main' package.\n",
           'Moose warns when loaded from the main package' );

stderr_is( sub { package main; eval 'use Moose::Role' },
           "Moose::Role does not export its sugar to the 'main' package.\n",
           'Moose::Role warns when loaded from the main package' );
