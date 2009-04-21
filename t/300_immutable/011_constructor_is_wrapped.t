#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Output;

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
        "Not inlining 'new' for Foo since it is not inheriting the default Moose::Object::new\nIf you are certain you don't need to inline your constructor, specify inline_constructor => 0 in your call to Foo->meta->make_immutable\n ('new' has method modifiers which would be lost if it were inlined)\n",
        'got a warning that Foo may not have an inlined constructor'
    );
}
