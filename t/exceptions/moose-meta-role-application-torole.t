
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util 'find_meta';

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
        find_meta($exception->role_name),
        Foo->meta,
        'Role Foo excludes Role Bar');

    is(
        $exception->excluded_role_name,
        "Bar",
        'Role Foo excludes Role Bar');

    is(
        find_meta($exception->excluded_role_name),
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
        $exception->second_role_name,
        "Foo2",
        'Role Bar2 does Role Bar3');

    is(
        find_meta($exception->second_role_name),
        Foo2->meta,
        'Role Bar2 does Role Bar3');

    is(
        $exception->excluded_role_name,
        "Bar3",
        'Role Bar2 does Role Bar3');

    is(
        find_meta($exception->excluded_role_name),
        Bar3->meta,
        'Role Bar2 does Role Bar3');

    is(
        $exception->role_name,
        "Bar2",
        'Role Bar2 does Role Bar3');

    is(
        find_meta($exception->role_name),
        Bar2->meta,
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
        find_meta($exception->role_name),
        Foo4->meta,
        'Role Foo4 & Role Bar4 has one common attribute named "foo"');

    is(
        $exception->second_role_name,
        "Bar4",
        'Role Foo4 & Role Bar4 has one common attribute named "foo"');

    is(
        find_meta($exception->second_role_name),
        Bar4->meta,
        'Role Foo4 & Role Bar4 has one common attribute named "foo"');

    is(
        $exception->attribute_name,
        'foo',
        'Role Foo4 & Role Bar4 has one common attribute named "foo"');
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
            use Moose::Role;
            with 'Foo5' => {
                -alias    => { foo5 => 'foo_in_bar' }
            };

            sub foo_in_bar { "test in foo" }
        }
    };

    like(
        $exception,
        qr/\QCannot create a method alias if a local method of the same name exists/,
        "Role Bar5 already has a method named foo_in_bar");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCreateMethodAliasLocalMethodIsPresent",
        "Role Bar5 already has a method named foo_in_bar");

    is(
        $exception->role_name,
        "Bar5",
        "Role Bar5 already has a method named foo_in_bar");

    is(
        find_meta($exception->role_name),
        Bar5->meta,
        "Role Bar5 already has a method named foo_in_bar");

    is(
        $exception->role_being_applied_name,
        "Foo5",
        "Role Bar5 already has a method named foo_in_bar");

    is(
        find_meta($exception->role_being_applied_name),
        Foo5->meta,
        "Role Bar5 already has a method named foo_in_bar");

    is(
        $exception->aliased_method_name,
        "foo_in_bar",
        "Role Bar5 already has a method named foo_in_bar");

    is(
        $exception->method->name,
        "foo5",
        "Role Bar5 already has a method named foo_in_bar");
}

{
    {
        package Foo6;
        use Moose::Role;

        override foo6 => sub { "override foo6" };
    }

    my $exception = exception {
        {
            package Bar6;
            use Moose::Role;
            with 'Foo6';

            sub foo6 { "test in foo6" }
        }
    };

    like(
        $exception,
        qr/\QRole 'Foo6' has encountered an 'override' method conflict during composition (A local method of the same name as been found). This is a fatal error./,
        "Role Foo6 is overriding a method named foo6, which is a local method in Bar6");

    isa_ok(
        $exception,
        "Moose::Exception::OverrideConflictInComposition",
        "Role Foo6 is overriding a method named foo6, which is a local method in Bar6");

    is(
        $exception->role_name,
        "Bar6",
        "Role Foo6 is overriding a method named foo6, which is a local method in Bar6");

    is(
        find_meta($exception->role_name),
        Bar6->meta,
        "Role Foo6 is overriding a method named foo6, which is a local method in Bar6");

    is(
        $exception->role_being_applied_name,
        "Foo6",
        "Role Foo6 is overriding a method named foo6, which is a local method in Bar6");

    is(
        find_meta($exception->role_being_applied_name),
        Foo6->meta,
        "Role Foo6 is overriding a method named foo6, which is a local method in Bar6");

    is(
        $exception->method_name,
        "foo6",
        "Role Foo6 is overriding a method named foo6, which is a local method in Bar6");
}

{
    {
        package Foo7;
        use Moose::Role;

        override foo7 => sub { "override foo7" };
    }

    my $exception = exception {
        {
            package Bar7;
            use Moose::Role;
            override foo7 => sub { "override foo7 in Bar7" };
            with 'Foo7';
        }
    };

    like(
        $exception,
        qr/\QRole 'Foo7' has encountered an 'override' method conflict during composition (Two 'override' methods of the same name encountered). This is fatal error./,
        "Roles Foo7 & Bar7, both have override foo7");

    isa_ok(
        $exception,
        "Moose::Exception::OverrideConflictInComposition",
        "Roles Foo7 & Bar7, both have override foo7");

    is(
        $exception->role_name,
        "Bar7",
        "Roles Foo7 & Bar7, both have override foo7");

    is(
        find_meta($exception->role_name),
        Bar7->meta,
        "Roles Foo7 & Bar7, both have override foo7");

    is(
        $exception->role_being_applied_name,
        "Foo7",
        "Roles Foo7 & Bar7, both have override foo7");

    is(
        find_meta($exception->role_being_applied_name),
        Foo7->meta,
        "Roles Foo7 & Bar7, both have override foo7");

    is(
        $exception->method_name,
        "foo7",
        "Roles Foo7 & Bar7, both have override foo7");
}

done_testing;
