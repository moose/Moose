#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception =  exception {
        my $method = Moose::Meta::TypeConstraint::Enum->new( values => []);
    };

    like(
        $exception,
        qr/You must have at least one value to enumerate through/,
        "an Array ref of zero length is given as values");

    isa_ok(
        $exception,
        "Moose::Exception::MustHaveAtLeastOneValueToEnumerate",
        "an Array ref of zero length is given as values");
}

{
    my $exception =  exception {
        my $method = Moose::Meta::TypeConstraint::Enum->new( values => [undef]);
    };

    like(
        $exception,
        qr/Enum values must be strings, not 'undef'/,
        "undef is given to values");

    isa_ok(
        $exception,
        "Moose::Exception::EnumValuesMustBeString",
        "undef is given to values");
}

{
    my $arrayRef = [1,2,3];
    my $exception =  exception {
        my $method = Moose::Meta::TypeConstraint::Enum->new( values => [$arrayRef]);
    };

    like(
        $exception,
        qr/\QEnum values must be strings, not '$arrayRef'/,
	"an array ref is given instead of a string");

    isa_ok(
        $exception,
        "Moose::Exception::EnumValuesMustBeString",
	"an array ref is given instead of a string");

    is(
	$exception->value,
	$arrayRef,
	"an array ref is given instead of a string");	
}

done_testing;
