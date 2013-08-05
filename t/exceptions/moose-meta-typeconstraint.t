#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;
use Moose();

# tests for type coercions
{
    subtype 'HexNum' => as 'Int', where { /[a-f0-9]/i };
    my $type_object = find_type_constraint 'HexNum';

    my $exception = exception {
        $type_object->coerce;
    };

    like(
        $exception,
        qr/Cannot coerce without a type coercion/,
        "You cannot coerce a type unless coercion is supported by that type");

    is(
        $exception->type->name,
        'HexNum',
        "You cannot coerce a type unless coercion is supported by that type");

    isa_ok(
        $exception,
        "Moose::Exception::CoercingWithoutCoercions",
        "You cannot coerce a type unless coercion is supported by that type");
}

{
    my $exception = exception {
        Moose::Meta::TypeConstraint->new( message => "foo");
    };

    like(
        $exception,
        qr/The 'message' parameter must be a coderef/,
	"'foo' is not a CODE ref");

    isa_ok(
        $exception,
        "Moose::Exception::MessageParameterMustBeCodeRef",
	"'foo' is not a CODE ref");
}

done_testing;
