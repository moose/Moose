#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Output";
plan skip_all => "Test::Output is required for this test" if $@;

plan tests => 1;

{
    package ModdedNew;
    use Moose;

    before 'new' => sub { };
}

{
    package Foo;
    use Moose;

    extends 'ModdedNew';

    ::stderr_is(
        sub { Foo->meta->make_immutable },
        "Not inlining a constructor for Foo since it is not inheriting the default Moose::Object constructor\n (constructor has method modifiers which would be lost if it were inlined)\n",
        'got a warning that Foo may not have an inlined constructor'
    );
}
