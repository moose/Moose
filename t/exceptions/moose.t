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
        "Moose::Exception::BadHasProvided",
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

done_testing;