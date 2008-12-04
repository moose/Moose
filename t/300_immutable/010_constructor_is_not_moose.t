#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Output";
plan skip_all => "Test::Output is required for this test" if $@;

plan tests => 4;

{
    package NotMoose;

    sub new {
        my $class = shift;

        return bless { not_moose => 1 }, $class;
    }
}

{
    package Foo;
    use Moose;

    extends 'NotMoose';

    ::stderr_is(
        sub { Foo->meta->make_immutable },
        "Not inlining a constructor for Foo since it is not inheriting the default Moose::Object constructor\n",
        'got a warning that Foo may not have an inlined constructor'
    );
}

is(
    Foo->meta->find_method_by_name('new')->body,
    NotMoose->can('new'),
    'Foo->new is inherited from NotMoose'
);

{
    package Bar;
    use Moose;

    extends 'NotMoose';

    ::stderr_is(
        sub { Foo->meta->make_immutable( replace_constructor => 1 ) },
        q{},
        'no warning when replace_constructor is true'
    );
}

isnt(
    Bar->meta->find_method_by_name('new')->body,
    Moose::Object->can('new'),
    'Bar->new is not inherited from NotMoose because it was inlined'
);
