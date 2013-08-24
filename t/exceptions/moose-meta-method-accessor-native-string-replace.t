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
            replace => 'replace'
        },
	required => 1
	);
}

my $foo_obj = Foo->new( foo => 'hello' );

{
    my $arg = [123];
    my $exception = exception { 
        $foo_obj->replace($arg);
    };

    like(
        $exception,
        qr/The first argument passed to replace must be a string or regexp reference/,
        "an Array ref passed to replace");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an Array ref passed to replace");

    is(
        $exception->argument,
        $arg,
        "an Array ref passed to replace");

    is(
        $exception->ordinal,
        "first",
        "an Array ref passed to replace");

    is(
        $exception->type_of_argument,
        "string or regexp reference",
        "an Array ref passed to replace");

    is(
        $exception->method_name,
	"replace",
        "an Array ref passed to replace");

    is(
        $exception->type,
        "Str|RegexpRef",
        "an Array ref passed to replace");
}

{
    my $arg = [123];
    my $exception = exception { 
        $foo_obj->replace('h', $arg);
    };

    like(
        $exception,
        qr/The second argument passed to replace must be a string or code reference/,
        "an Array ref passed to replace");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an Array ref passed to replace");

    is(
        $exception->argument,
        $arg,
        "an Array ref passed to replace");

    is(
        $exception->ordinal,
        "second",
        "an Array ref passed to replace");

    is(
        $exception->type_of_argument,
        "string or code reference",
        "an Array ref passed to replace");

    is(
        $exception->method_name,
	"replace",
        "an Array ref passed to replace");

    is(
        $exception->type,
        "Str|CodeRef",
        "an Array ref passed to replace");
}

done_testing;
