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

done_testing;
