#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
	package Foo;
	use Moose;
	__PACKAGE__->meta->make_immutable;
	__PACKAGE__->meta->superclasses("Bar");
    };

    like(
        $exception,
        qr/The 'superclasses' method is read-only when called on an immutable instance/,
        "calling 'foo' on an immutable instance");

    isa_ok(
        $exception,
        "Moose::Exception::CallingReadOnlyMethodOnAnImmutableInstance",
        "calling 'foo' on an immutable instance");

    is(
        $exception->method_name,
        "superclasses",
        "calling 'foo' on an immutable instance");
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	__PACKAGE__->meta->make_immutable;
	__PACKAGE__->meta->add_method( foo => sub { "foo" } );
    };

    like(
        $exception,
        qr/The 'add_method' method cannot be called on an immutable instance/,
	"calling 'add_method' on an immutable instance");

    isa_ok(
        $exception,
        "Moose::Exception::CallingMethodOnAnImmutableInstance",
	"calling 'add_method' on an immutable instance");

    is(
        $exception->method_name,
        "add_method",
	"calling 'add_method' on an immutable instance");
}

done_testing;
