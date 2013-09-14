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
            isa     => 'ArrayRef',
            traits  => ['Array'],
            handles => {
                grep => 'grep'
            },
            required => 1
        );
    }

    my $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->grep( $arg );
    };

    like(
        $exception,
        qr/The argument passed to grep must be a code reference/,
        "an ArrayRef passed to grep");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to grep");

    is(
        $exception->method_name,
        "grep",
        "an ArrayRef passed to grep");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to grep");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to grep");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to grep");
}

done_testing;
