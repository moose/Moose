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
}

{
    package Foo::Moose;
    use Moose;

    extends 'Foo';

    has class => (
        is => 'rw',
    );

    has accum => (
        is      => 'rw',
        isa     => 'Str',
        default => '',
    );

    sub BUILD {
        my $self = shift;
        $self->class(ref $self);
        $self->accum($self->accum . 'a');
    }
}

{
    package Foo::Moose::Sub;
    use Moose;

    extends 'Foo::Moose';

    has bar => (
        is => 'rw',
    );

    sub BUILD {
        my $self = shift;
        $self->bar('BAR');
        $self->accum($self->accum . 'b');
    }
}

{
    my $foo_moose = Foo::Moose->new;
    is($foo_moose->class, 'Foo::Moose', 'BUILD method called properly');
    is($foo_moose->accum, 'a', 'BUILD method called properly');
}

{
    my $foo_moose_sub = Foo::Moose::Sub->new;
    is($foo_moose_sub->class, 'Foo::Moose::Sub', 'parent BUILD method called');
    is($foo_moose_sub->bar, 'BAR', 'child BUILD method called');
    is($foo_moose_sub->accum, 'ab',
       'BUILD methods called in the correct order');
}

done_testing;
