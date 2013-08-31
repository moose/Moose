#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    {
        package Foo;
        use Moose;

        has 'foo' => (
            is      => 'ro',
            isa     => 'HashRef',
            traits  => ['Hash'],
            handles => {
                set => 'set',
            },
            required => 1
        );
    }
}

my $foo_obj = Foo->new( foo => { 1 => "one"} );

{
    my $exception = exception {
        $foo_obj->set(1 => "foo", "bar");
    };

    like(
        $exception,
        qr/You must pass an even number of arguments to set/,
        "odd number of arguments passed to set");

    isa_ok(
        $exception,
        'Moose::Exception::MustPassEvenNumberOfArguments',
        "odd number of arguments passed to set");

    is(
        $exception->method_name,
        "set",
        "odd number of arguments passed to set");
}

{
    my $exception = exception {
        $foo_obj->set(undef, "foo");
    };

    like(
        $exception,
        qr/Hash keys passed to set must be defined/,
        "undef is passed to set");

    isa_ok(
        $exception,
        'Moose::Exception::UndefinedHashKeysPassedToMethod',
        "undef is passed to set");

    is(
        $exception->method_name,
        "set",
        "undef is passed to set");
}

done_testing;
