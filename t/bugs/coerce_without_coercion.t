use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

{
    package Foo;

    use Moose;

    ::like(
        ::exception {
            has x => (
                is     => 'rw',
                isa    => 'HashRef',
                coerce => 1,
            )
        },
        qr/You cannot coerce an attribute \(x\) unless its type \(HashRef\) has a coercion/,
        "can't set coerce on an attribute whose type constraint has no coercion"
    );
}

done_testing;
