#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

use Moose::Util::TypeConstraints;
use Class::MOP::Attribute;

{
    my $exception =  exception {
	my $class = Class::MOP::Attribute->new;
    };

    like(
        $exception,
        qr/You must provide a name for the attribute/,
        "no attribute name given to new");

    isa_ok(
        $exception,
        "Moose::Exception::MOPAttributeNewNeedsAttributeName",
        "no attribute name given to new");
}

{
    my $exception =  exception {
        Class::MOP::Attribute->new( "foo", ( builder => [123] ));
    };

    like(
        $exception,
        qr/builder must be a defined scalar value which is a method name/,
        "an array ref is given as builder");

    isa_ok(
        $exception,
        "Moose::Exception::BuilderMustBeAMethodName",
        "an array ref is given as builder");
}

{
    my $exception =  exception {
        Class::MOP::Attribute->new( "foo", ( builder => "bar", default => "xyz" ));
    };

    like(
        $exception,
        qr/\QSetting both default and builder is not allowed./,
        "builder & default, both are given");

    isa_ok(
        $exception,
        "Moose::Exception::BothBuilderAndDefaultAreNotAllowed",
        "builder & default, both are given");
}

{
    my $exception =  exception {
	Class::MOP::Attribute->new( "foo", ( default => [1] ) );
    };

    like(
        $exception,
        qr/\QReferences are not allowed as default values, you must wrap the default of 'foo' in a CODE reference (ex: sub { [] } and not [])/,
	"default value can't take references");

    isa_ok(
        $exception,
        "Moose::Exception::ReferencesAreNotAllowedAsDefault",
	"default value can't take references");

    is(
        $exception->attribute_name,
        "foo",
	"default value can't take references");
}

{
    my $exception =  exception {
	Class::MOP::Attribute->new( "foo", ( required => 1, init_arg => undef ) );
    };

    like(
        $exception,
        qr/A required attribute must have either 'init_arg', 'builder', or 'default'/,
	"no 'init_arg', 'builder' or 'default' is given");

    isa_ok(
        $exception,
        "Moose::Exception::RequiredAttributeLacksInitialization",
	"no 'init_arg', 'builder' or 'default' is given");
}

{
    my $exception =  exception {
        my $foo = Class::MOP::Attribute->new("bar", ( required => 1, init_arg => undef, builder => 'foo'));
        $foo->initialize_instance_slot( $foo->meta, $foo );
    };

    like(
        $exception,
        qr/\QClass::MOP::Attribute does not support builder method 'foo' for attribute 'bar'/,
        "given builder method doesn't exist");

    isa_ok(
        $exception,
        "Moose::Exception::BuilderMethodNotSupportedForAttribute",
        "given builder method doesn't exist");

    is(
        $exception->attribute->name,
        "bar",
        "given builder method doesn't exist");

    is(
        $exception->attribute->builder,
        "foo",
        "given builder method doesn't exist");
}

{
    my $exception =  exception {
        my $foo = Class::MOP::Attribute->new("foo");
        $foo->attach_to_class( "Foo" );
    };

    like(
        $exception,
        qr/\QYou must pass a Class::MOP::Class instance (or a subclass)/,
        "attach_to_class expects an instance Class::MOP::Class or its subclass");

    isa_ok(
        $exception,
        "Moose::Exception::AttachToClassNeedsAClassMOPClassInstanceOrASubclass",
        "attach_to_class expects an instance Class::MOP::Class or its subclass");

    is(
        $exception->attribute->name,
        "foo",
        "attach_to_class expects an instance Class::MOP::Class or its subclass");

    is(
        $exception->class,
        "Foo",
        "attach_to_class expects an instance Class::MOP::Class or its subclass");
}

{
    my $array = ["foo"];
    my $bar = Class::MOP::Attribute->new("bar", ( is => 'ro', predicate => $array));
    my $exception =  exception {
        $bar->install_accessors;
    };

    like(
        $exception,
        qr!bad accessor/reader/writer/predicate/clearer format, must be a HASH ref!,
        "an array reference is given to predicate");

    isa_ok(
        $exception,
        "Moose::Exception::BadOptionFormat",
        "an array reference is given to predicate");

    is(
        $exception->attribute->name,
        "bar",
        "an array reference is given to predicate");

    is(
        $exception->option_name,
        "predicate",
        "an array reference is given to predicate");

    is(
        $exception->option_value,
        $array,
        "an array reference is given to predicate");
}

{
    my $bar = Class::MOP::Attribute->new("bar", ( is => 'ro', predicate => "foo"));
    my $exception =  exception {
        $bar->install_accessors;
    };

    like(
        $exception,
        qr/\QCould not create the 'predicate' method for bar because : Can't call method "name" on an undefined value/,
        "Can't call method 'name' on an undefined value");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotCreateMethod",
        "Can't call method 'name' on an undefined value");

    is(
        $exception->attribute->name,
        "bar",
        "Can't call method 'name' on an undefined value");

    is(
        $exception->option_name,
        "predicate",
        "Can't call method 'name' on an undefined value");

    is(
        $exception->option_value,
        "foo",
        "Can't call method 'name' on an undefined value");
}

done_testing;
