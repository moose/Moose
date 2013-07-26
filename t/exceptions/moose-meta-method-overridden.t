#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

{
    my $exception =  exception {
        package Foo;
	use Moose;

        override foo => sub {}
    };

    like(
        $exception,
        qr/You cannot override 'foo' because it has no super method/,
        "Foo class is not extending any class");

    isa_ok(
        $exception,
        "Moose::Exception::CannotOverrideNoSuperMethod",
        "Foo class is not extending any class");

    is(
	$exception->class,
	"Moose::Meta::Method::Overridden",
        "Foo class is not extending any class");

    is(
	$exception->method_name,
	"foo",
        "Foo class is not extending any class");
}

done_testing;
