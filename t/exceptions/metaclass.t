#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

{
    {
	package Foo;
	use Moose;
    }

    my $exception = exception {
	require metaclass;
	metaclass->import( ("Foo") );
    };

    like(
        $exception,
        qr/\QThe metaclass (Foo) must be derived from Class::MOP::Class/,
        "Foo is not derived from Class::MOP::Class");

    is(
        $exception->class_name,
        'Foo',
        "Foo is not derived from Class::MOP::Class");

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassMustBeDerivedFromClassMOPClass",
        "Foo is not derived from Class::MOP::Class");
}

done_testing;
