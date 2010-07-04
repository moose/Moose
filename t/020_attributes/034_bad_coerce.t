#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package Foo;

    use Moose;

    ::throws_ok{ has foo => (
            is     => 'ro',
            isa    => 'Str',
            coerce => 1,
        );
        } qr/\QYou cannot coerce an attribute (foo) unless its type has a coercion/,
        'Cannot coerce unless the type has a coercion';
}

done_testing;
