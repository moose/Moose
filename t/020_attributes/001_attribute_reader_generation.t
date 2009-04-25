#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;



{
    package Foo;
    use Moose;

    eval {
        has 'foo' => (
            reader => 'get_foo'
        );
    };
    ::ok(!$@, '... created the reader method okay');

    eval {
        has 'lazy_foo' => (
            reader => 'get_lazy_foo',
            lazy => 1,
            default => sub { 10 }
        );
    };
    ::ok(!$@, '... created the lazy reader method okay') or warn $@;
}

{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    can_ok($foo, 'get_foo');
    is($foo->get_foo(), undef, '... got an undefined value');
    dies_ok {
        $foo->get_foo(100);
    } '... get_foo is a read-only';

    ok(!exists($foo->{lazy_foo}), '... no value in get_lazy_foo slot');

    can_ok($foo, 'get_lazy_foo');
    is($foo->get_lazy_foo(), 10, '... got an deferred value');
    dies_ok {
        $foo->get_lazy_foo(100);
    } '... get_lazy_foo is a read-only';
}

{
    my $foo = Foo->new(foo => 10, lazy_foo => 100);
    isa_ok($foo, 'Foo');

    is($foo->get_foo(), 10, '... got the correct value');
    is($foo->get_lazy_foo(), 100, '... got the correct value');
}



