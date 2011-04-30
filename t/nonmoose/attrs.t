#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;

    sub new {
        my $class = shift;
        bless { @_ }, $class;
    }

    sub foo {
        my $self = shift;
        return $self->{foo} unless @_;
        $self->{foo} = shift;
    }
}

{
    package Foo::Moose;
    use Moose;

    extends 'Foo';

    has bar => (
        is => 'rw',
    );
}

{
    my $foo_moose = Foo::Moose->new(foo => 'FOO', bar => 'BAR');
    is($foo_moose->foo, 'FOO', 'foo set in constructor');
    is($foo_moose->bar, 'BAR', 'bar set in constructor');
    $foo_moose->foo('BAZ');
    $foo_moose->bar('QUUX');
    is($foo_moose->foo, 'BAZ', 'foo set by accessor');
    is($foo_moose->bar, 'QUUX', 'bar set by accessor');
}

done_testing;
