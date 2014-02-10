
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

# tests for type/subtype name contain invalid characters
{
    my $exception = exception {
        subtype 'Foo-Baz' => as 'Item'
    };

    like(
        $exception,
        qr/contains invalid characters/,
        "Type names cannot contain a dash (via subtype sugar)");

    isa_ok(
        $exception,
        "Moose::Exception::InvalidNameForType",
        "Type names cannot contain a dash (via subtype sugar)");
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
	$exception->type_name,
	'Foo1',
        "there is an already defined role of name 'Foo1'");

    is(
	(find_type_constraint($exception->type_name))->_package_defined_in,
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
	$exception->type_name,
	'Foo2',
        "there is an already defined class of name 'Foo2'");

    is(
	(find_type_constraint($exception->type_name))->_package_defined_in,
	'Moose',
        "there is an already defined class of name 'Foo2'");

    is(
        $exception->package_defined_in,
        'main',
        "there is an already defined class of name 'Foo2'");
}

{
    my $exception = exception {
        subtype 'Foo';
    };

    like(
        $exception,
        qr/A subtype cannot consist solely of a name, it must have a parent/,
        "no parent given to subtype");

    isa_ok(
        $exception,
        "Moose::Exception::NoParentGivenToSubtype",
        "no parent given to subtype");

    is(
        $exception->name,
        'Foo',
        "no parent given to subtype");
}

{
    my $exception = exception {
        enum [1,2,3], "foo";
    };

    like(
        $exception,
        qr/\Qenum called with an array reference and additional arguments. Did you mean to parenthesize the enum call's parameters?/,
        "enum expects either a name & an array or only an array");

    isa_ok(
        $exception,
        "Moose::Exception::EnumCalledWithAnArrayRefAndAdditionalArgs",
        "enum expects either a name & an array or only an array");
}

{
    my $exception = exception {
        union [1,2,3], "foo";
    };

    like(
        $exception,
        qr/union called with an array reference and additional arguments/,
        "union expects either a name & an array or only an array");

    isa_ok(
        $exception,
        "Moose::Exception::UnionCalledWithAnArrayRefAndAdditionalArgs",
        "union expects either a name & an array or only an array");
}

{
    {
        package Foo3;
        use Moose;
    }

    my $exception = exception {
        Moose::Util::TypeConstraints::type("Foo3");
    };

    like(
        $exception,
        qr/\QThe type constraint 'Foo3' has already been created in Moose and cannot be created again in main/,
        "there is an already defined class of name 'Foo3'");

    isa_ok(
        $exception,
        "Moose::Exception::TypeConstraintIsAlreadyCreated",
        "there is an already defined class of name 'Foo3'");

    is(
	$exception->type_name,
	'Foo3',
        "there is an already defined class of name 'Foo3'");

    is(
	find_type_constraint($exception->type_name)->_package_defined_in,
	'Moose',
        "there is an already defined class of name 'Foo3'");

    is(
        $exception->package_defined_in,
        'main',
        "there is an already defined class of name 'Foo3'");
}

{
    my $exception = exception {
        Moose::Util::TypeConstraints::coerce "Foo";
    };

    like(
        $exception,
        qr/Cannot find type 'Foo', perhaps you forgot to load it/,
        "'Foo' is not a valid type");

    isa_ok(
        $exception,
        "Moose::Exception::CannotFindType",
        "'Foo' is not a valid type");
}

{
    my $exception = exception {
        Moose::Util::TypeConstraints::add_parameterizable_type "Foo";
    };

    like(
        $exception,
        qr/Type must be a Moose::Meta::TypeConstraint::Parameterizable not Foo/,
        "'Foo' is not a parameterizable type");

    isa_ok(
        $exception,
        "Moose::Exception::AddParameterizableTypeTakesParameterizableType",
        "'Foo' is not a parameterizable type");

    is(
        $exception->type_name,
        "Foo",
        "'Foo' is not a parameterizable type");
}

done_testing;
