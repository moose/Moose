#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Method::Wrapped->wrap("Foo");
    };

    like(
        $exception,
        qr/\QCan only wrap blessed CODE/,
        "no CODE is given to wrap");

    isa_ok(
        $exception,
        "Moose::Exception::CanOnlyWrapBlessedCode",
        "no CODE is given to wrap");
}

done_testing;
