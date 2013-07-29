#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Method::Meta->wrap("Foo", ( body => 'foo' ));
    };

    like(
        $exception,
        qr/\QOverriding the body of meta methods is not allowed/,
	"body is given to Class::MOP::Method::Meta->wrap");

    isa_ok(
        $exception,
        "Moose::Exception::CannotOverrideBodyOfMetaMethods",
	"body is given to Class::MOP::Method::Meta->wrap");
}

done_testing;
