#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

use Moose::Util::TypeConstraints;
use Class::MOP::Class;

{
    my $exception =  exception {
	my $class = Class::MOP::Class::initialize;
    };

    like(
        $exception,
        qr/You must pass a package name and it cannot be blessed/,
        "no package name given to initialize");

    isa_ok(
        $exception,
        "Moose::Exception::InitializeTakesUnBlessedPackageName",
        "no package name given to initialize");
}

{
    my $exception =  exception {
	my $class = Class::MOP::Class::create("Foo" => ( superclasses => ('foo') ));
    };

    like(
        $exception,
        qr/You must pass an ARRAY ref of superclasses/,
        "an Array is of superclasses is passed");

    isa_ok(
        $exception,
        "Moose::Exception::CreateMOPClassTakesArrayRefOfSuperclasses",
        "an Array is of superclasses is passed");

    is(
	$exception->class,
	'Foo',
        "an Array is of superclasses is passed");
}


{
    my $exception =  exception {
	my $class = Class::MOP::Class::create("Foo" => ( attributes => ('foo') ));
    };

    like(
        $exception,
        qr/You must pass an ARRAY ref of attributes/,
        "an Array is of attributes is passed");

    isa_ok(
        $exception,
        "Moose::Exception::CreateMOPClassTakesArrayRefOfAttributes",
        "an Array is of attributes is passed");

    is(
	$exception->class,
	'Foo',
        "an Array is of attributes is passed");
}

{
    my $exception =  exception {
	my $class = Class::MOP::Class::create("Foo" => ( methods => ('foo') ) );
    };

    like(
        $exception,
        qr/You must pass an HASH ref of methods/,
        "a Hash is of methods is passed");

    isa_ok(
        $exception,
        "Moose::Exception::CreateMOPClassTakesHashRefOfMethods",
        "a Hash is of methods is passed");

    is(
	$exception->class,
	'Foo',
        "a Hash is of methods is passed");
}

done_testing;
