#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package Foo;

    # Moose will issue a warning if we try to load it from the main
    # package.
    ::use_ok('Moose');
}

done_testing;
