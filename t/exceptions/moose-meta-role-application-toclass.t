#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    {
        package BarRole;
        use Moose::Role;
    }

    {
        package RoleExcludingBarRole;
        use Moose::Role;
        excludes 'BarRole';
    }

    my $exception = exception {
        {
            package FooClass;
            use Moose;

            with 'RoleExcludingBarRole';
            with 'BarRole';
        }
    };

    like(
        $exception,
        qr/\QConflict detected: FooClass excludes role 'BarRole'/,
        'class FooClass excludes Role BarRole');

    isa_ok(
        $exception,
        "Moose::Exception::ConflictDetectedInCheckRoleExclusionsInToClass",
        'class FooClass excludes Role BarRole');

    is(
        $exception->class_name,
        "FooClass",
        'class FooClass excludes Role BarRole');

    is(
        $exception->class,
        FooClass->meta,
        'class FooClass excludes Role BarRole');

    is(
        $exception->role_name,
        "BarRole",
        'class FooClass excludes Role BarRole');

    is(
        $exception->role,
        BarRole->meta,
        'class FooClass excludes Role BarRole');
}

{
    {
        package BarRole2;
        use Moose::Role;
        excludes 'ExcludedRole2';
    }

    {
        package ExcludedRole2;
        use Moose::Role;
    }

    my $exception = exception {
        {
            package FooClass2;
            use Moose;

            with 'ExcludedRole2';
            with 'BarRole2';
        }
    };

    like(
        $exception,
        qr/\QThe class FooClass2 does the excluded role 'ExcludedRole2'/,
        'Class FooClass2 does Role ExcludedRole2');

    isa_ok(
        $exception,
        "Moose::Exception::ClassDoesTheExcludedRole",
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->role_name,
        "BarRole2",
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->role,
        BarRole2->meta,
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->excluded_role->name,
        "ExcludedRole2",
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->excluded_role,
        ExcludedRole2->meta,
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->class_name,
        "FooClass2",
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->class,
        FooClass2->meta,
        'Class FooClass2 does Role ExcludedRole2');
}

{
    {
        package Foo5;
        use Moose::Role;

        sub foo5 { "foo" }
    }

    my $exception = exception {
        {
            package Bar5;
            use Moose;
            with 'Foo5' => {
                -alias    => { foo5 => 'foo_in_bar' }
            };

            sub foo_in_bar { "test in foo" }
        }
    };

    like(
        $exception,
        qr/\QCannot create a method alias if a local method of the same name exists/,
        "Class Bar5 already has a method named foo_in_bar");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCreateMethodAliasLocalMethodIsPresentInClass",
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->role_name,
        "Foo5",
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->role,
        Foo5->meta,
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->class->name,
        "Bar5",
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->class,
        Bar5->meta,
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->aliased_method_name,
        "foo_in_bar",
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->method->name,
        "foo5",
        "Class Bar5 already has a method named foo_in_bar");
}

done_testing;
