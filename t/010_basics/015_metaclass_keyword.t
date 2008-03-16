#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Moose');
}

{

    package Foo;
    use Moose;

    ::is( metaclass(), __PACKAGE__->meta, 'metaclass and __PACKAGE__->meta are the same' );
}

