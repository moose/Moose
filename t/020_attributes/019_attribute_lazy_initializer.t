#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use Moose;
    
    has 'foo' => (
        reader => 'get_foo',
        writer => 'set_foo',
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;
            $callback->($value * 2);
        },
    );

    has 'lazy_foo' => (
        reader  => 'get_lazy_foo',
        default => 10,
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;
            $callback->($value * 2);
        },
    );
}

{
    my $foo = Foo->new(foo => 10);
    isa_ok($foo, 'Foo');

    is($foo->get_foo,      20, 'initial value set to 2x given value');
    is($foo->get_lazy_foo, 20, 'initial lazy value set to 2x given value');
}



