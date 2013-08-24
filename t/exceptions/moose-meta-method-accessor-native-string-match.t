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
            match   => 'match'
	},
	required => 1
	);
}

my $foo_obj = Foo->new( foo => 'hello' );

{
    my $arg = [12];
    my $exception = exception {
        $foo_obj->match( $arg );
    };

    like(
        $exception,
        qr/The argument passed to match must be a string or regexp reference/,
        "an Array Ref passed to match");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an Array Ref passed to match");

    is(
        $exception->argument,
        $arg,
        "an Array Ref passed to match");

   is(
        $exception->type_of_argument,
        "string or regexp reference",
        "an Array Ref passed to match");

    is(
        $exception->method_name,
	"match",
        "an Array Ref passed to match");

    is(
        $exception->type,
        "Str|RegexpRef",
        "an Array Ref passed to match");
}

done_testing;
