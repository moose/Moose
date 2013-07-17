#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;
use Moose::Util::TypeConstraints;

# tests for type/subtype name contain invalid characters
{
    like(
        exception {
            subtype 'Foo-Baz' => as 'Item'
        }, qr/contains invalid characters/,
        "Type names cannot contain a dash (via subtype sugar)");

    isa_ok(
        exception {
            subtype 'Foo-Baz' => as 'Item';
        }, "Moose::Exception::InvalidNameForType",
        "Type names cannot contain a dash (via subtype sugar)");
}

# tests for type coercions
{
    use Moose;
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
	Moose::Util::TypeConstraints::create_type_constraint_union();
    };

    like(
        $exception,
        qr/You must pass in at least 2 type names to make a union/,
	"Moose::Util::TypeConstraints::create_type_constraint_union takes atleast two arguments");

    isa_ok(
        $exception,
        "Moose::Exception::UnionTakesAtleastTwoTypeNames",
	"Moose::Util::TypeConstraints::create_type_constraint_union takes atleast two arguments");
}

{
    my $exception = exception {
	Moose::Util::TypeConstraints::create_type_constraint_union('foo','bar');
    };

    like(
        $exception,
        qr/\QCould not locate type constraint (foo) for the union/,
	"invalid typeconstraint given to Moose::Util::TypeConstraints::create_type_constraint_union");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotLocateTypeConstraintForUnion",
	"invalid typeconstraint given to Moose::Util::TypeConstraints::create_type_constraint_union");

    is(
	$exception->type_name,
	'foo',
	"invalid typeconstraint given to Moose::Util::TypeConstraints::create_type_constraint_union");
}

{
    my $exception = exception {
	Moose::Util::TypeConstraints::create_parameterized_type_constraint("Foo");
    };

    like(
        $exception,
        qr/\QCould not parse type name (Foo) correctly/,
	"'Foo' is not a valid type constraint name");

    isa_ok(
        $exception,
        "Moose::Exception::InvalidTypeGivenToCreateParameterizedTypeConstraint",
	"'Foo' is not a valid type constraint name");
}

{
    my $exception = exception {
	Moose::Util::TypeConstraints::create_parameterized_type_constraint("Foo[Int]");
    };

    like(
        $exception,
        qr/\QCould not locate the base type (Foo)/,
	"'Foo' is not a valid base type constraint name");

    isa_ok(
        $exception,
        "Moose::Exception::InvalidBaseTypeGivenToCreateParameterizedTypeConstraint",
	"'Foo' is not a valid base type constraint name");
}

{
    {
	package Foo1;
	use Moose::Role;
    }

    my $exception = exception {
	Moose::Util::TypeConstraints::class_type("Foo1");
    };

    like(
        $exception,
        qr/\QThe type constraint 'Foo1' has already been created in Moose::Role and cannot be created again in main/,
        "there is an already defined role of name 'Foo1'");

    isa_ok(
        $exception,
        "Moose::Exception::TypeConstraintIsAlreadyCreated",
        "there is an already defined role of name 'Foo1'");

    is(
	$exception->type->name,
	'Foo1',
        "there is an already defined role of name 'Foo1'");

    is(
	$exception->type->_package_defined_in,
	'Moose::Role',
        "there is an already defined role of name 'Foo1'");

    is(
	$exception->package_defined_in,
	'main',
        "there is an already defined role of name 'Foo1'");
}

{
    {
	package Foo2;
	use Moose;
    }

    my $exception = exception {
	Moose::Util::TypeConstraints::role_type("Foo2");
    };

    like(
        $exception,
        qr/\QThe type constraint 'Foo2' has already been created in Moose and cannot be created again in main/,
        "there is an already defined class of name 'Foo2'");

    isa_ok(
        $exception,
        "Moose::Exception::TypeConstraintIsAlreadyCreated",
        "there is an already defined class of name 'Foo2'");

    is(
	$exception->type->name,
	'Foo2',
        "there is an already defined class of name 'Foo2'");

    is(
	$exception->type->_package_defined_in,
	'Moose',
        "there is an already defined class of name 'Foo2'");

    is(
	$exception->package_defined_in,
	'main',
        "there is an already defined class of name 'Foo1'");
}

done_testing;
