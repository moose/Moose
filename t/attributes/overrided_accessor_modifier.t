#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package Foo;

    use Moose;

    has 'foo' => (
        is        => 'ro',
        writer    => 'set_foo',
        predicate => 'has_foo',
    );

    has 'set_foo_arounded' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    has 'has_foo_arounded' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    around 'has_foo' => sub {
        my $orig = shift;
        my $self = shift;

        $self->has_foo_arounded($self->has_foo_arounded + 1);

        $self->$orig(@_);
    };

    around 'set_foo' => sub {
        my $orig = shift;
        my $self = shift;

        $self->set_foo_arounded($self->set_foo_arounded + 1);

        $self->$orig(@_);
    };
}

{
    package MyFoo;

    use Moose;

    sub push { return; };
}

{
    package Bar;

    use Moose;

    extends 'Foo';

    has '+foo' => (
        lazy => 0,
    );

    has 'bar' => (
        is      => 'ro',
        isa     => 'MyFoo',
        reader  => 'get_bar',
        default => sub { MyFoo->new(); },
        handles => [qw/push/],
    );

    has 'get_bar_arounded' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    has 'bar_handle_arounded' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    around 'has_foo' => sub {
        my $orig = shift;
        my $self = shift;

        $self->has_foo_arounded($self->has_foo_arounded + 1);

        $self->$orig(@_);
    };

    around 'set_foo' => sub
    {
        my $orig = shift;
        my $self = shift;

        $self->set_foo_arounded($self->set_foo_arounded + 1);

        $self->$orig(@_);
    };

    around 'get_bar' => sub
    {
        my $orig = shift;
        my $self = shift;

        $self->get_bar_arounded($self->get_bar_arounded + 1);

        $self->$orig(@_);
    };

    around 'push' => sub
    {
        my $orig = shift;
        my $self = shift;

        $self->bar_handle_arounded($self->bar_handle_arounded + 1);

        $self->$orig(@_);
    };
}

{
    package Baz;

    use Moose;

    extends 'Bar';

    has '+bar' => (
        lazy => 0,
    );

    around 'has_foo' => sub {
        my $orig = shift;
        my $self = shift;

        $self->has_foo_arounded($self->has_foo_arounded + 1);

        $self->$orig(@_);
    };

    around 'get_bar' => sub
    {
        my $orig = shift;
        my $self = shift;

        $self->get_bar_arounded($self->get_bar_arounded + 1);

        $self->$orig(@_);
    };

    around 'push' => sub
    {
        my $orig = shift;
        my $self = shift;

        $self->bar_handle_arounded($self->bar_handle_arounded + 1);

        $self->$orig(@_);
    };
}

{
    my $foo = Foo->new;

    isa_ok($foo, 'Foo');

    $foo->has_foo();
    $foo->set_foo(1);

    is($foo->has_foo_arounded, 1, '... got hte correct value');
    is($foo->set_foo_arounded, 1, '... got hte correct value');

    my $bar = Bar->new;

    isa_ok($bar, 'Bar');

    $bar->has_foo();
    is($bar->has_foo_arounded, 2, '... got hte correct value');

    $bar->set_foo(1);
    is($bar->set_foo_arounded, 2, '... got hte correct value');

    $bar->get_bar();
    is($bar->get_bar_arounded, 1, '... got hte correct value');

    $bar->push(1);
    # method delegation calls reader internally
    # Moose/Meta/Method/Delegation.pm
    is($bar->get_bar_arounded, 2, '... got hte correct value');
    is($bar->bar_handle_arounded, 1, '... got hte correct value');

    my $baz = Baz->new;

    isa_ok($baz, 'Baz');

    $baz->has_foo();
    is($baz->has_foo_arounded, 3, '... got hte correct value');

    $baz->set_foo(1);
    is($baz->set_foo_arounded, 2, '... got hte correct value');

    $baz->get_bar();
    is($baz->get_bar_arounded, 2, '... got hte correct value');

    $baz->push(1);
    is($baz->get_bar_arounded, 4, '... got hte correct value');
    is($baz->bar_handle_arounded, 2, '... got hte correct value');
}

done_testing;
