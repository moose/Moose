#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
    plan tests => 1;
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
        qr/\QNot inlining 'new' for Foo since it is not inheriting the default Moose::Object::new\E\s+\QIf you are certain you don't need to inline your constructor, specify inline_constructor => 0 in your call to Foo->meta->make_immutable\E\s+\Q ('new' has method modifiers which would be lost if it were inlined)/,
        'got a warning that Foo may not have an inlined constructor'
    );
}
