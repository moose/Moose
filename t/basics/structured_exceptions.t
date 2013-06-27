#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

# tests for extends without arguments
{
    like(
        exception {
            package SubClassNoSuperClass;
            use Moose;
            extends;
        }, qr/Must derive at least one class/,
        "extends requires at least one argument");

    isa_ok(
        exception {
            package SubClassNoSuperClass;
            use Moose;
            extends;
        }, 'Moose::Exception::ExtendsMissingArgs',
        "extends requires at least one argument");
}

# tests for class consuming a class, instead of role
{
    like(
        exception {
            package ClassConsumingClass;
            use Moose;
            use DateTime;
            with 'DateTime';
        }, qr/You can only consume roles, DateTime is not a Moose role/,
        "You can't consume a class");

    isa_ok(
        exception {
            package ClassConsumingClass;
            use Moose;
            use DateTime;
            with 'DateTime';
	}, 'Moose::Exception::CanOnlyConsumeRole',
        "You can't consume a class");

    like(
        exception {
            package foo;
            use Moose;
	    use DateTime;
            with 'Not::A::Real::Package';
        }, qr!You can only consume roles, Not::A::Real::Package is not a Moose role!,
        "You can't consume a class which doesn't exist");

    like(
        exception {
            package foo;
            use Moose;
	    use DateTime;
            with sub {};
        }, qr/argument is not a module name/,
        "You can only consume a module");
}

# tests for type/subtype name contain invalid characters
{
    like(
        exception {
            use Moose::Util::TypeConstraints;
            subtype 'Foo-Baz' => as 'Item'
        }, qr/contains invalid characters/,
        "Type names cannot contain a dash (via subtype sugar)");

    isa_ok(
        exception {
            use Moose::Util::TypeConstraints;
            subtype 'Foo-Baz' => as 'Item';
        }, "Moose::Exception::InvalidNameForType",
        "Type names cannot contain a dash (via subtype sugar)");
}

# tests for type coercions
{
    use Moose;
    use Moose::Util::TypeConstraints;
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

# tests for AccessorMustReadWrite
{
    use Moose;

    my $exception = exception {
        has 'test' => (
            is       => 'ro',
            isa      => 'Int',
            accessor => 'bar',
        )
    };

    like(
        $exception,
        qr!Cannot define an accessor name on a read-only attribute, accessors are read/write!,
        "Read-only attributes can't have accessor");

    is(
        $exception->attribute_name,
        'test',
        "Read-only attributes can't have accessor");

    isa_ok(
        $exception,
        "Moose::Exception::AccessorMustReadWrite",
        "Read-only attributes can't have accessor");
}

# tests for SingleParamsToNewMustBeHRef
{
    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        Foo->new("hello")
    };

    like(
        $exception,
        qr/^\QSingle parameters to new() must be a HASH ref/,
        "A single non-hashref arg to a constructor throws an error");

    isa_ok(
        $exception,
        "Moose::Exception::SingleParamsToNewMustBeHRef",
        "A single non-hashref arg to a constructor throws an error");
}

# tests for DoesRequiresRoleName
{
    {
        package Foo;
        use Moose;
    }

    my $foo = Foo->new;

    my $exception = exception {
        $foo->does;
    };

    like(
        $exception,
        qr/^\QYou must supply a role name to does()/,
        "Cannot call does() without a role name");

    isa_ok(
        $exception,
        "Moose::Exception::DoesRequiresRoleName",
        "Cannot call does() without a role name");
}

done_testing;
