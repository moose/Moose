#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Output";
plan skip_all => "Test::Output is required for this test" if $@;

plan tests => 1;

{
    package Foo;
    use Moose;
    __PACKAGE__->meta->make_immutable;
}
TODO: {
    package Bar;
    use Moose;

    extends 'Foo';

    __PACKAGE__->meta->make_immutable;
    __PACKAGE__->meta->make_mutable;

    use Test::More;
    local $TODO = 'Known bug';

    ::stderr_unlike(
        sub { Bar->meta->make_immutable },
        qr/Not inlining a constructor/,
        'no warning that Bar may not have an inlined constructor'
    );
}

