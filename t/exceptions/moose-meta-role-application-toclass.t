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

done_testing;
