#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        my $rolesComp = Moose::Meta::Role::Composite->new(roles => ["foo"]);
    };

    like(
        $exception,
        qr/\QThe list of roles must be instances of Moose::Meta::Role, not foo/,
	"'foo' is not an instance of Moose::Meta::Role");

    isa_ok(
        $exception,
        "Moose::Exception::RolesListMustBeInstancesOfMooseMetaRole",
	"'foo' is not an instance of Moose::Meta::Role");

    is(
        $exception->role,
        "foo",
	"'foo' is not an instance of Moose::Meta::Role");
}

{
    {
        package Foo;
        use Moose::Role;
    }

    my $rolesComp = Moose::Meta::Role::Composite->new(roles => [Foo->meta]);
    my $exception = exception {
        $rolesComp->add_method;
    };

    like(
        $exception,
        qr/You must define a method name/,
        "no method name given to add_method");

    isa_ok(
        $exception,
        "Moose::Exception::MustDefineAMethodName",
        "no method name given to add_method");

    is(
        $exception->instance,
        $rolesComp,
        "no method name given to add_method");
}

{
    {
        package Foo;
        use Moose::Role;
    }

    my $rolesComp = Moose::Meta::Role::Composite->new(roles => [Foo->meta]);
    my $exception = exception {
        $rolesComp->reinitialize;
    };

    like(
        $exception,
        qr/Moose::Meta::Role::Composite instances can only be reinitialized from an existing metaclass instance/,
        "no metaclass instance is given");

    isa_ok(
        $exception,
        "Moose::Exception::CannotInitializeMooseMetaRoleComposite",
        "no metaclass instance is given");

    is(
        $exception->role_composite,
        $rolesComp,
        "no metaclass instance is given");
}

done_testing;
