#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception =  exception {
        my $method = Moose::Meta::Method::Destructor->new( options => (1,2,3));
    };

    like(
        $exception,
        qr/You must pass a hash of options/,
	"options is not a HASH ref");

    isa_ok(
        $exception,
        "Moose::Exception::MustPassAHashOfOptions",
	"options is not a HASH ref");
}

{
    my $exception =  exception {
        my $method = Moose::Meta::Method::Destructor->new( options => {});
    };

    like(
        $exception,
        qr/You must supply the package_name and name parameters/,
	"package_name and name are not given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyPackageNameAndName",
	"package_name and name are not given");
}

{
    my $exception =  exception {
        my $method = Moose::Meta::Method::Destructor->is_needed("foo");
    };

    like(
        $exception,
        qr/The is_needed method expected a metaclass object as its arugment/,
	"'foo' is not a metaclass");

    isa_ok(
        $exception,
        "Moose::Exception::MethodExpectedAMetaclassObject",
	"'foo' is not a metaclass");

    is(
	$exception->metaclass,
	'foo',
	"'foo' is not a metaclass");
}

{
    {
        package TestClass;
        use Moose;
    }

    {
        package SubClassDestructor;
        use Moose;
        extends 'Moose::Meta::Method::Destructor';

        sub _generate_DEMOLISHALL {
            return "print 'xyz"; # this is an intentional syntax error
        }
    }

    my $methodDestructor;
    my $exception = exception {
        $methodDestructor = SubClassDestructor->new( name => "xyz", package_name => "Xyz", options => {}, metaclass => TestClass->meta);
    };

    like(
        $exception,
        qr/Could not eval the destructor/,
        "syntax error in the return value of _generate_DEMOLISHALL");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotEvalDestructor",
        "syntax error in the return value of _generate_DEMOLISHALL");
}

done_testing;
