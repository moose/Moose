#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Method::Overload->wrap("Foo");
    };

    like(
        $exception,
        qr/\Qoperator is required/,
        "no operator is given to Class::MOP::Method::Overload::wrap");

    isa_ok(
        $exception,
        "Moose::Exception::OperatorIsRequired",
        "no operator is given to Class::MOP::Method::Overload::wrap");
}

done_testing;
