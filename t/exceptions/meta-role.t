
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    {
        package JustATestRole;
        use Moose::Role;
    }

    {
        package JustATestClass;
        use Moose;
    }

    my $class = JustATestClass->meta;
    my $exception = exception {
        JustATestRole->meta->add_attribute( $class );
    };

    like(
        $exception,
        qr/\QCannot add a Moose::Meta::Class as an attribute to a role/,
        "Roles cannot have a class as an attribute");

    isa_ok(
        $exception,
        "Moose::Exception::CannotAddAsAnAttributeToARole",
        "Roles cannot have a class as an attribute");

    is(
        $exception->role_name,
        'JustATestRole',
        "Roles cannot have a class as an attribute");

    is(
        $exception->attribute_class,
        "Moose::Meta::Class",
        "Roles cannot have a class as an attribute");
}

{
    my $exception = exception {
        package JustATestRole;
        use Moose::Role;

        has '+attr' => (
            is => 'ro',
        );
    };

    like(
        $exception,
        qr/\Qhas '+attr' is not supported in roles/,
        "Attribute Extension is not supported in roles");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeExtensionIsNotSupportedInRoles",
        "Attribute Extension is not supported in roles");

    is(
        $exception->role_name,
        'JustATestRole',
        "Attribute Extension is not supported in roles");

    is(
        $exception->attribute_name,
        "+attr",
        "Attribute Extension is not supported in roles");
}

{
    my $exception = exception {
        package JustATestRole;
        use Moose::Role;

        sub bar {}

        override bar => sub {};
    };

    like(
        $exception,
        qr/\QCannot add an override of method 'bar' because there is a local version of 'bar'/,
        "Cannot override bar, because it's a local method");

    isa_ok(
        $exception,
        "Moose::Exception::CannotOverrideALocalMethod",
        "Cannot override bar, because it's a local method");

    is(
        $exception->role_name,
        'JustATestRole',
        "Cannot override bar, because it's a local method");

    is(
        $exception->method_name,
        "bar",
        "Cannot override bar, because it's a local method");
}

{
    {
        package JustATestRole;
        use Moose::Role;
    }

    my $exception = exception {
        JustATestRole->meta->add_role("xyz");
    };

    like(
        $exception,
        qr/\QRoles must be instances of Moose::Meta::Role/,
        "add_role to Moose::Meta::Role takes instances of Moose::Meta::Role");

    isa_ok(
        $exception,
        "Moose::Exception::AddRoleToARoleTakesAMooseMetaRole",
        "add_role to Moose::Meta::Role takes instances of Moose::Meta::Role");

    is(
        $exception->role_name,
        'JustATestRole',
        "add_role to Moose::Meta::Role takes instances of Moose::Meta::Role");

    is(
        $exception->role_to_be_added,
        "xyz",
        "add_role to Moose::Meta::Role takes instances of Moose::Meta::Role");
}

{
    {
        package Bar;
        use Moose::Role;
    }

    my $exception = exception {
        Bar->meta->does_role;
    };

    like(
        $exception,
        qr/You must supply a role name to look for/,
        "Cannot call does_role without a role name");

    isa_ok(
        $exception,
        'Moose::Exception::RoleNameRequiredForMooseMetaRole',
        "Cannot call does_role without a role name");

    is(
        $exception->role_name,
        'Bar',
        "Cannot call does_role without a role name");
}

{
    {
        package Bar;
        use Moose::Role;
    }

    my $exception = exception {
        Bar->meta->apply("xyz");
    };

    like(
        $exception,
        qr/You must pass in an blessed instance/,
        "apply takes a blessed instance");

    isa_ok(
        $exception,
        'Moose::Exception::ApplyTakesABlessedInstance',
        "apply takes a blessed instance");

    is(
        $exception->role_name,
        'Bar',
        "apply takes a blessed instance");

    is(
        $exception->param,
        'xyz',
        "apply takes a blessed instance");
}

{
    my $exception = exception {
        Moose::Meta::Role->create("TestRole", ( 'attributes' => 'bar'));
    };

    like(
        $exception,
        qr/You must pass a HASH ref of attributes/,
        "create takes a HashRef of attributes");

    isa_ok(
        $exception,
        "Moose::Exception::CreateTakesHashRefOfAttributes",
        "create takes a HashRef of attributes");
}

{
    my $exception = exception {
        Moose::Meta::Role->create("TestRole", ( 'methods' => 'bar'));
    };

    like(
        $exception,
        qr/You must pass a HASH ref of methods/,
        "create takes a HashRef of methods");

    isa_ok(
        $exception,
        "Moose::Exception::CreateTakesHashRefOfMethods",
        "create takes a HashRef of methods");
}

{
    my $exception = exception {
        Moose::Meta::Role->create("TestRole", ('roles', 'bar'));
    };

    like(
        $exception,
        qr/You must pass an ARRAY ref of roles/,
        "create takes an ArrayRef of roles");

    isa_ok(
        $exception,
        "Moose::Exception::CreateTakesArrayRefOfRoles",
        "create takes an ArrayRef of roles");
}

done_testing;
