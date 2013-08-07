#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

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

{
    my $exception = exception {
        {
            package Foo1;
            use Moose;
            has 'bar' => (
                is =>
            );
        }
    };

    like(
        $exception,
        qr/\QUsage: has 'name' => ( key => value, ... )/,
        "has takes a hash");

    isa_ok(
        $exception,
        "Moose::Exception::InvalidHasProvided",
        "has takes a hash");

    is(
        $exception->attribute_name,
        'bar',
        "has takes a hash");

    is(
        $exception->class->name,
        'Foo1',
        "has takes a hash");
}

{
    my $exception = exception {
        use Moose;
        Moose->init_meta;
    };

    like(
        $exception,
        qr/Cannot call init_meta without specifying a for_class/,
        "for_class is not given");

    isa_ok(
        $exception,
        "Moose::Exception::InitMetaRequiresClass",
        "for_class is not given");
}

{
    my $exception = exception {
        use Moose;
        Moose->init_meta( (for_class => 'Foo2', metaclass => 'Foo2' ));
    };

    like(
        $exception,
        qr/\QThe Metaclass Foo2 must be loaded. (Perhaps you forgot to 'use Foo2'?)/,
        "Foo2 is not loaded");

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassNotLoaded",
        "Foo2 is not loaded");

    is(
	$exception->class_name,
	"Foo2",
	"Foo2 is not loaded");
}

{
    {
	package Foo3;
	use Moose::Role;
    }

    my $exception = exception {
        use Moose;
        Moose->init_meta( (for_class => 'Foo3', metaclass => 'Foo3' ));
    };

    like(
        $exception,
        qr/\QThe Metaclass Foo3 must be a subclass of Moose::Meta::Class./,
        "Foo3 is a Moose::Role");

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassMustBeASubclassOfMooseMetaClass",
        "Foo3 is a Moose::Role");

    is(
	$exception->class_name,
	"Foo3",
	"Foo3 is not loaded");
}

{
    {
	package Foo3;
	use Moose::Role;
    }

    my $exception = exception {
        use Moose;
        Moose->init_meta( (for_class => 'Foo3' ));
    };

    my $foo3 = Foo3->meta;

    like(
        $exception,
        qr/\QFoo3 already has a metaclass, but it does not inherit Moose::Meta::Class ($foo3). You cannot make the same thing a role and a class. Remove either Moose or Moose::Role./,
        "Foo3 is a Moose::Role");

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassIsARoleNotASubclassOfGivenMetaclass",
        "Foo3 is a Moose::Role");

    is(
        $exception->role_name,
        "Foo3",
        "Foo3 is a Moose::Role");

    is(
        $exception->role,
        Foo3->meta,
        "Foo3 is a Moose::Role");

    is(
        $exception->metaclass,
        "Moose::Meta::Class",
        "Foo3 is a Moose::Role");
}

{
    my $foo;
    {
	use Moose;
	$foo = Class::MOP::Class->create("Foo4");
    }

    my $exception = exception {
        use Moose;
        Moose->init_meta( (for_class => 'Foo4' ));
    };

    like(
        $exception,
        qr/\QFoo4 already has a metaclass, but it does not inherit Moose::Meta::Class ($foo)./,
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Class");

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassIsNotASubclassOfGivenMetaclass",
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Class");

    is(
        $exception->class_name,
        "Foo4",
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Class");

    is(
        $exception->class,
        $foo,
        "Foo3 is a Class::MOP::Class, not a Moose::Meta::Class");

    is(
        $exception->metaclass,
        "Moose::Meta::Class",
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Class");
}

done_testing;
