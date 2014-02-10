
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    my $exception =  exception {
        Moose::Meta::Class->create(
            'Made::Of::Fail',
            superclasses => ['Class'],
            roles        => 'Foo',
            );
    };

    like(
        $exception,
        qr/You must pass an ARRAY ref of roles/,
        "create takes an Array of roles");

    isa_ok(
        $exception,
        "Moose::Exception::RolesInCreateTakesAnArrayRef",
        "create takes an Array of roles");
}

{
    use Moose::Meta::Class;

    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        Foo->meta->add_role('Bar');
    };

    like(
        $exception,
        qr/Roles must be instances of Moose::Meta::Role/,
        "add_role takes an instance of Moose::Meta::Role");

    isa_ok(
        $exception,
        'Moose::Exception::AddRoleTakesAMooseMetaRoleInstance',
        "add_role takes an instance of Moose::Meta::Role");

    is(
        $exception->class->name,
        'Foo',
        "add_role to Moose::Meta::Role takes instances of Moose::Meta::Role");

    is(
        $exception->role_to_be_added,
        "Bar",
        "add_role to Moose::Meta::Role takes instances of Moose::Meta::Role");
}

{
    my $exception = exception {
        package Foo;
        use Moose;
        Foo->meta->add_role_application();
    };

    like(
        $exception,
        qr/Role applications must be instances of Moose::Meta::Role::Application::ToClass/,
        "bar is not an instance of Moose::Meta::Role::Application::ToClass");

    isa_ok(
        $exception,
        "Moose::Exception::InvalidRoleApplication",
        "bar is not an instance of Moose::Meta::Role::Application::ToClass");
}

# tests for Moose::Meta::Class::does_role
{
    use Moose::Meta::Class;

    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        Foo->meta->does_role;
    };

    like(
        $exception,
        qr/You must supply a role name to look for/,
        "Cannot call does_role without a role name");

    isa_ok(
        $exception,
        'Moose::Exception::RoleNameRequired',
        "Cannot call does_role without a role name");

    is(
        $exception->class->name,
        'Foo',
        "Cannot call does_role without a role name");
}

# tests for Moose::Meta::Class::excludes_role
{
    use Moose::Meta::Class;

    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        Foo->meta->excludes_role;
    };

    like(
        $exception,
        qr/You must supply a role name to look for/,
        "Cannot call excludes_role without a role name");

    isa_ok(
        $exception,
        'Moose::Exception::RoleNameRequired',
        "Cannot call excludes_role without a role name");

    is(
        $exception->class->name,
        'Foo',
        "Cannot call excludes_role without a role name");
}

{
    my $exception = exception {
        package Foo;
        use Moose;
        __PACKAGE__->meta->make_immutable;
        Foo->new([])
    };

    like(
        $exception,
        qr/^\QSingle parameters to new() must be a HASH ref/,
        "A single non-hashref arg to a constructor throws an error");

    isa_ok(
        $exception,
        "Moose::Exception::SingleParamsToNewMustBeHashRef",
        "A single non-hashref arg to a constructor throws an error");
}

# tests for AttributeIsRequired for inline excpetions
{
    {
        package Foo2;
        use Moose;

        has 'baz' => (
            is       => 'ro',
            isa      => 'Int',
            required => 1,
        );
        __PACKAGE__->meta->make_immutable;
    }

    my $exception = exception {
        my $test1 = Foo2->new;
    };

    like(
        $exception,
        qr/\QAttribute (baz) is required/,
        "... must supply all the required attribute");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeIsRequired",
        "... must supply all the required attribute");

    is(
        $exception->attribute->name,
        'baz',
        "... must supply all the required attribute");

    isa_ok(
        $exception->class_name,
        'Foo2',
        "... must supply all the required attribute");
}

{
    {
        package Bar;
        use Moose::Role;
    }

    my $exception = exception {
        package Foo3;
        use Moose;
        extends 'Bar';
    };

    like(
        $exception,
        qr/^\QYou cannot inherit from a Moose Role (Bar)/,
        "Class cannot extend a role");

    isa_ok(
        $exception,
        'Moose::Exception::CanExtendOnlyClasses',
        "Class cannot extend a role");

    is(
        $exception->role->name,
        'Bar',
        "Class cannot extend a role");
}

{
    my $exception = exception {
        package Foo;
        use Moose;
        sub foo2 {}
        override foo2 => sub {};
    };

    like(
        $exception,
        qr/Cannot add an override method if a local method is already present/,
        "there is already a method named foo2 defined in the class, so you can't override it");

    isa_ok(
        $exception,
        'Moose::Exception::CannotOverrideLocalMethodIsPresent',
        "there is already a method named foo2 defined in the class, so you can't override it");

    is(
        $exception->class->name,
        'Foo',
        "there is already a method named foo2 defined in the class, so you can't override it");

    is(
        $exception->method->name,
        'foo2',
        "there is already a method named foo2 defined in the class, so you can't override it");
}

{
    my $exception = exception {
        package Foo;
        use Moose;
        sub foo {}
        augment foo => sub {};
    };

    like(
        $exception,
        qr/Cannot add an augment method if a local method is already present/,
        "there is already a method named foo defined in the class");

    isa_ok(
        $exception,
        'Moose::Exception::CannotAugmentIfLocalMethodPresent',
        "there is already a method named foo defined in the class");

    is(
        $exception->class->name,
        'Foo',
        "there is already a method named foo defined in the class");

    is(
        $exception->method->name,
        'foo',
        "there is already a method named foo defined in the class");
}

{
    {
        package Test;
        use Moose;
    }

    my $exception = exception {
        package Test2;
        use Moose;
        extends 'Test';
        has '+bar' => ( default => 100 );
    };

    like(
        $exception,
        qr/Could not find an attribute by the name of 'bar' to inherit from in Test2/,
        "attribute 'bar' is not defined in the super class");

    isa_ok(
        $exception,
        "Moose::Exception::NoAttributeFoundInSuperClass",
        "attribute 'bar' is not defined in the super class");
}

done_testing;
