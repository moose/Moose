#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    {
        package Foo;
        use Moose::Role;
        excludes 'Bar';
    }

    {
        package Bar;
        use Moose::Role;
    }

    my $exception = exception {
        Moose::Meta::Role::Application::ToRole->check_role_exclusions( Bar->meta, Foo->meta );
    };

    like(
        $exception,
        qr/\QConflict detected: Foo excludes role 'Bar'/,
        'Role Foo excludes Role Bar');

    isa_ok(
        $exception,
        "Moose::Exception::ConflictDetectedInCheckRoleExclusions",
        'Role Foo excludes Role Bar');

    is(
        $exception->role_name,
        "Foo",
        'Role Foo excludes Role Bar');

    is(
        $exception->role,
        Foo->meta,
        'Role Foo excludes Role Bar');

    is(
        $exception->excluded_role->name,
        "Bar",
        'Role Foo excludes Role Bar');

    is(
        $exception->excluded_role,
        Bar->meta,
        'Role Foo excludes Role Bar');   
}

{
    {
        package Foo2;
        use Moose::Role;
        excludes 'Bar3';
    }

    {
        package Bar2;
        use Moose::Role;
        with 'Bar3';
    }

    {
        package Bar3;
        use Moose::Role;
    }

    my $exception = exception {
        Moose::Meta::Role::Application::ToRole->check_role_exclusions( Foo2->meta, Bar2->meta );
    };

    like(
        $exception,
        qr/\QThe role Bar2 does the excluded role 'Bar3'/,
        'Role Bar2 does Role Bar3');

    isa_ok(
        $exception,
        "Moose::Exception::RoleDoesTheExcludedRole",
        'Role Bar2 does Role Bar3');

    is(
        $exception->role_name,
        "Bar2",
        'Role Bar2 does Role Bar3');

    is(
        $exception->role,
        Bar2->meta,
        'Role Bar2 does Role Bar3');
    
    is(
        $exception->excluded_role->name,
        "Bar3",
        'Role Bar2 does Role Bar3');

    is(
        $exception->excluded_role,
        Bar3->meta,
        'Role Bar2 does Role Bar3');
}

{
    {
        package Foo4;
        use Moose::Role;

        has 'foo' => (
            is  => 'ro',
            isa => 'Int'
	);
    }

    {
        package Bar4;
        use Moose::Role;

        has 'foo' => (
            is  => 'ro',
            isa => 'Int'
	);
    }

    my $exception = exception {
        Moose::Meta::Role::Application::ToRole->apply_attributes( Foo4->meta, Bar4->meta );
    };

    like(
        $exception,
        qr/\QRole 'Foo4' has encountered an attribute conflict while being composed into 'Bar4'. This is a fatal error and cannot be disambiguated. The conflicting attribute is named 'foo'./,
	'Role Foo4 & Role Bar4 has one common attribute named "foo"');

    isa_ok(
        $exception,
        "Moose::Exception::AttributeConflictInRoles",
	'Role Foo4 & Role Bar4 has one common attribute named "foo"');

    is(
        $exception->role_name,
        "Foo4",
	'Role Foo4 & Role Bar4 has one common attribute named "foo"');

    is(
        $exception->role,
        Foo4->meta,
	'Role Foo4 & Role Bar4 has one common attribute named "foo"');
    
    is(
        $exception->second_role->name,
        "Bar4",
	'Role Foo4 & Role Bar4 has one common attribute named "foo"');

    is(
        $exception->second_role,
        Bar4->meta,
	'Role Foo4 & Role Bar4 has one common attribute named "foo"');

    is(
        $exception->attribute_name,
        'foo',
	'Role Foo4 & Role Bar4 has one common attribute named "foo"');
}

done_testing;
