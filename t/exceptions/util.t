#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util qw/apply_all_roles add_method_modifier/;

use Try::Tiny;

{
    {
        package TestClass;
        use Moose;
    }

    my $test_object = TestClass->new;

    my $exception = exception {
        apply_all_roles( $test_object );
    };

    like(
        $exception,
        qr/\QMust specify at least one role to apply to $test_object/,
        "apply_all_roles takes an object and a role to apply");

    isa_ok(
        $exception,
        "Moose::Exception::MustSpecifyAtleastOneRoleToApplicant",
        "apply_all_roles takes an object and a role to apply");

    my $test_class = TestClass->meta;

    $exception = exception {
        apply_all_roles( $test_class );
    };

    like(
        $exception,
        qr/\QMust specify at least one role to apply to $test_class/,
        "apply_all_roles takes a class and a role to apply");

    isa_ok(
        $exception,
        "Moose::Exception::MustSpecifyAtleastOneRoleToApplicant",
        "apply_all_roles takes a class and a role to apply");

    {
        package TestRole;
        use Moose::Role;
    }

    my $test_role = TestRole->meta;

    $exception = exception {
        apply_all_roles( $test_role );
    };

    like(
        $exception,
        qr/\QMust specify at least one role to apply to $test_role/,
        "apply_all_roles takes a role and a role to apply");

    isa_ok(
        $exception,
        "Moose::Exception::MustSpecifyAtleastOneRoleToApplicant",
        "apply_all_roles takes a role and a role to apply");
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
        }, qr!Can't locate Not/A/Real/Package\.pm!,
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

{
    {
	package Foo;
	use Moose;
    }

    my $exception = exception {
	add_method_modifier(Foo->meta, "before", [{}, sub {"before";}]);
    };

    like(
        $exception,
        qr/\QMethods passed to before must be provided as a list, arrayref or regex, not HASH/,
        "we gave a HashRef to before");

    isa_ok(
        $exception,
        "Moose::Exception::IllegalMethodTypeToAddMethodModifier",
        "we gave a HashRef to before");

    is(
	ref( $exception->params->[0] ),
	"HASH",
        "we gave a HashRef to before");

    is(
	$exception->modifier_name,
	'before',
        "we gave a HashRef to before");

    is(
	$exception->class_or_object->name,
	"Foo",
        "we gave a HashRef to before");
}

done_testing;
