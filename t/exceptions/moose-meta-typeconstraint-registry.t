#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose;

{
    my $tr = Moose::Meta::TypeConstraint::Registry->new();

    my $exception = exception {
        $tr->add_type_constraint('xyz');
    };

    like(
        $exception,
        qr!No type supplied / type is not a valid type constraint!,
        "'xyz' is not a Moose::Meta::TypeConstraint");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidTypeConstraint',
        "'xyz' is not a Moose::Meta::TypeConstraint");
}

done_testing;
