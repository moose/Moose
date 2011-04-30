#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;

    sub new {
        my $class = shift;
        bless { foo => 'FOO' }, $class;
    }

    sub foo { shift->{foo} }
}

{
    package Foo::Moose;
    use Moose;

    extends 'Foo';

    has bar => (
        is      => 'ro',
        default => 'BAR',
    );
}

{
    package Foo::Moose::Sub;
    use Moose;
    extends 'Foo::Moose';

    has baz => (
        is      => 'ro',
        default => 'BAZ',
    );
}

{
    my $foo_moose = Foo::Moose->new;
    is($foo_moose->foo, 'FOO', 'Foo::Moose::foo');
    is($foo_moose->bar, 'BAR', 'Foo::Moose::bar');
    isnt(Foo::Moose->meta->get_method('new'), undef,
         'Foo::Moose gets its own constructor');
}

{
    my $foo_moose_sub = Foo::Moose::Sub->new;
    is($foo_moose_sub->foo, 'FOO', 'Foo::Moose::Sub::foo');
    is($foo_moose_sub->bar, 'BAR', 'Foo::Moose::Sub::bar');
    is($foo_moose_sub->baz, 'BAZ', 'Foo::Moose::Sub::baz');
    is(Foo::Moose::Sub->meta->get_method('new'), undef,
       'Foo::Moose::Sub just uses the constructor for Foo::Moose');
}

Foo::Moose->meta->make_immutable;
Foo::Moose::Sub->meta->make_immutable;

{
    my $foo_moose_sub = Foo::Moose::Sub->new;
    is($foo_moose_sub->foo, 'FOO', 'Foo::Moose::Sub::foo (immutable)');
    is($foo_moose_sub->bar, 'BAR', 'Foo::Moose::Sub::bar (immutable)');
    is($foo_moose_sub->baz, 'BAZ', 'Foo::Moose::Sub::baz (immutable)');
    isnt(Foo::Moose::Sub->meta->get_method('new'), undef,
         'Foo::Moose::Sub has an inlined constructor');
}

done_testing;
