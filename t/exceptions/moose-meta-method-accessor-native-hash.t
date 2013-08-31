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
                exists => 'exists'
            },
            required => 1
        );
    }

    my $foo_obj = Foo->new( foo => { 1 => "one"} );
    my $arg = undef;

    my $exception = exception {
        $foo_obj->exists( undef );
    };

    like(
        $exception,
        qr/The key passed to exists must be a defined value/,
        "an undef is passed to exists");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod', 
        "an undef is passed to exists");

    is(
        $exception->method_name,
        "exists",
        "an undef is passed to exists");

    is(
        $exception->argument,
        $arg,
        "an undef is passed to exists");

    is(
        $exception->type_of_argument,
        "defined value",
        "an undef is passed to exists");

    is(
        $exception->type,
        "Defined",
        "an undef is passed to exists");
}

done_testing;
