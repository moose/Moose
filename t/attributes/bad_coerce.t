use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Foo;

    use Moose;

    ::like(::exception {
        has foo => (
            is     => 'ro',
            isa    => 'Str',
            coerce => 1,
        );
        },
        qr/\QYou cannot coerce an attribute (foo) unless its type (Str) has a coercion/,
        'Cannot coerce unless the type has a coercion');

    ::like(::exception {
        has bar => (
            is     => 'ro',
            isa    => 'Str',
            coerce => 1,
        );
        },
        qr/\QYou cannot coerce an attribute (bar) unless its type (Str) has a coercion/,
        'Cannot coerce unless the type has a coercion - different attribute');
}

done_testing;
