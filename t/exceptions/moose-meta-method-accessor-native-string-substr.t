#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    package Foo;
    use Moose;

    has 'foo' => (
	is      => 'ro',
	isa     => 'Str',
	traits  => ['String'],
	handles => {
            substr => 'substr'
        },
	required => 1
	);
}

my $foo_obj = Foo->new( foo => 'hello' );

{
    my $exception = exception { 
        $foo_obj->substr(1.1);
    };

    like(
        $exception,
        qr/The first argument passed to substr must be an integer/,
        "substr takes integer as its first argument");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "substr takes integer as its first argument");

    is(
        $exception->argument,
        1.1,
        "substr takes integer as its first argument");

    is(
        $exception->ordinal,
        "first",
        "substr takes integer as its first argument");

    is(
        $exception->type_of_argument,
        "integer",
        "substr takes integer as its first argument");

    is(
        $exception->method_name,
	"substr",
        "substr takes integer as its first argument");

    is(
        $exception->type,
        "Int",
        "substr takes integer as its first argument");
}

{
    my $exception = exception { 
        $foo_obj->substr(1, 1.2);
    };

    like(
        $exception,
        qr/The second argument passed to substr must be an integer/,
        "substr takes integer as its second argument");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "substr takes integer as its second argument");

    is(
        $exception->argument,
        1.2,
        "substr takes integer as its second argument");

    is(
        $exception->ordinal,
        "second",
        "substr takes integer as its second argument");

    is(
        $exception->type_of_argument,
        "integer",
        "substr takes integer as its second argument");

    is(
        $exception->method_name,
	"substr",
        "substr takes integer as its second argument");

    is(
        $exception->type,
        "Int",
        "substr takes integer as its second argument");
}

{
    my $arg = [122];
    my $exception = exception { 
        $foo_obj->substr(1, 2, $arg);
    };

    like(
        $exception,
        qr/The third argument passed to substr must be a string/,
        "substr takes string as its third argument");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "substr takes string as its third argument");

    is(
        $exception->argument,
        $arg,
        "substr takes string as its third argument");

    is(
        $exception->ordinal,
        "third",
        "substr takes string as its third argument");

    is(
        $exception->type_of_argument,
        "string",
        "substr takes string as its third argument");

    is(
        $exception->method_name,
	"substr",
        "substr takes string as its third argument");

    is(
        $exception->type,
        "Str",
        "substr takes string as its third argument");
}

done_testing;
