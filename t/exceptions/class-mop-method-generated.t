#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Method::Generated->new;
    };

    like(
        $exception,
        qr/\QClass::MOP::Method::Generated is an abstract base class, you must provide a constructor./,
        "trying to call an abstract base class constructor");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCallAnAbstractBaseMethod",
        "trying to call an abstract base class constructor");
}

{
    my $exception = exception {
        Class::MOP::Method::Generated->_initialize_body;
    };

    like(
        $exception,
        qr/\QNo body to initialize, Class::MOP::Method::Generated is an abstract base class/,
        "trying to call a method of an abstract class");

    isa_ok(
        $exception,
        "Moose::Exception::NoBodyToInitializeInAnAbstractBaseClass",
        "trying to call a method of an abstract class");
}

done_testing;
