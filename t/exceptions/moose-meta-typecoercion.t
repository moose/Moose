#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

{
    subtype 'typeInt',
    as 'Int';

    my $exception = exception {
        coerce 'typeInt', 
	from 'xyz';
    };

    like(
        $exception,
        qr/\QCould not find the type constraint (xyz) to coerce from/,
        "xyz is not a valid type constraint");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotFindTypeConstraintToCoerceFrom",
        "xyz is not a valid type constraint");

    is(
        $exception->constraint_name,
        "xyz",
        "xyz is not a valid type constraint");
}

{
    subtype 'typeInt',
    as 'Int';

    my $exception = exception {
	coerce 'typeInt', from 'Int', via  { "123" };
	coerce 'typeInt', from 'Int', via  { 12 };
    };

    like(
        $exception,
        qr/\QA coercion action already exists for 'Int'/,
	"coercion already exists");

    isa_ok(
        $exception,
        "Moose::Exception::CoercionAlreadyExists",
	"coercion already exists");

    is(
	$exception->constraint_name,
	"Int",
	"coercion already exists");
}

done_testing;
