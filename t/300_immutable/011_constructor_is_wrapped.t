#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
}

{
    package ModdedNew;
    use Moose;

    before 'new' => sub { };
}

{
    package Foo;
    use Moose;

    extends 'ModdedNew';

    ::stderr_like(
        sub { Foo->meta->make_immutable },
        qr/\QNot inlining 'new' for Foo since it has method modifiers which would be lost if it were inlined/,
        'got a warning that Foo may not have an inlined constructor'
    );
}

done_testing;
