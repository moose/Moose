#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

use Moose::Meta::Role::Application;

{
    my $exception =  exception {
	Moose::Meta::Role::Application->check_role_exclusions;
    };

    like(
        $exception,
        qr/Abstract method/,
        "cannot call an abstract method");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCallAnAbstractMethod",
        "cannot call an abstract method");
}

{
    my $exception =  exception {
	Moose::Meta::Role::Application->check_required_methods;
    };

    like(
        $exception,
        qr/Abstract method/,
        "cannot call an abstract method");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCallAnAbstractMethod",
        "cannot call an abstract method");
}

{
    my $exception =  exception {
	Moose::Meta::Role::Application->check_required_attributes;
    };

    like(
        $exception,
        qr/Abstract method/,
        "cannot call an abstract method");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCallAnAbstractMethod",
        "cannot call an abstract method");
}

{
    my $exception =  exception {
	Moose::Meta::Role::Application->apply_attributes;
    };

    like(
        $exception,
        qr/Abstract method/,
        "cannot call an abstract method");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCallAnAbstractMethod",
        "cannot call an abstract method");
}

{
    my $exception =  exception {
	Moose::Meta::Role::Application->apply_methods;
    };

    like(
        $exception,
        qr/Abstract method/,
        "cannot call an abstract method");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCallAnAbstractMethod",
        "cannot call an abstract method");
}

{
    my $exception =  exception {
	Moose::Meta::Role::Application->apply_override_method_modifiers;
    };

    like(
        $exception,
        qr/Abstract method/,
        "cannot call an abstract method");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCallAnAbstractMethod",
        "cannot call an abstract method");
}

{
    my $exception =  exception {
	Moose::Meta::Role::Application->apply_method_modifiers;
    };

    like(
        $exception,
        qr/Abstract method/,
        "cannot call an abstract method");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCallAnAbstractMethod",
        "cannot call an abstract method");
}

done_testing;
