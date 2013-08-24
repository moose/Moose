#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Moose::Meta::Method::Delegation->new;
    };

    like(
        $exception,
        qr/You must supply an attribute to construct with/,
        "no attribute is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyAnAttributeToConstructWith",
        "no attribute is given");
}

{
    my $exception = exception {
        Moose::Meta::Method::Delegation->new( attribute => "foo" );
    };

    like(
        $exception,
        qr/\QYou must supply an attribute which is a 'Moose::Meta::Attribute' instance/,
        "attribute is not an instance of Moose::Meta::Attribute");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyAMooseMetaAttributeInstance",
        "attribute is not an instance of Moose::Meta::Attribute");
}

{
    my $attr = Moose::Meta::Attribute->new("foo");
    my $exception = exception {
        Moose::Meta::Method::Delegation->new( attribute => $attr );
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
    my $attr = Moose::Meta::Attribute->new("foo");
    my $exception = exception {
        Moose::Meta::Method::Delegation->new( attribute => $attr, package_name => "Foo", name => "Foo" );
    };

    like(
        $exception,
        qr/You must supply a delegate_to_method which is a method name or a CODE reference/,
        "delegate_to_method is not given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyADelegateToMethod",
        "delegate_to_method is not given");
}

{
    my $attr = Moose::Meta::Attribute->new("foo");
    my $exception = exception {
        Moose::Meta::Method::Delegation->new( attribute => $attr,
					      package_name => "Foo",
					      name => "Foo",
					      delegate_to_method => sub {},
					      curried_arguments => {} );
    };

    like(
        $exception,
        qr/You must supply a curried_arguments which is an ARRAY reference/,
	"curried_arguments not given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyAnArrayRefAsCurriedArguments",
	"curried_arguments not given");
}

{
    {
        package BadClass;
        use Moose;

        has 'foo' => (
            is      => 'ro',
            handles => { get_count => 'count' }
        );
    }

    my $object = BadClass->new;

    my $exception = exception {
        $object->get_count;
    };

    like(
        $exception,
        qr/Cannot delegate get_count to count because the value of foo is not defined/,
        "foo is not set");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeValueIsNotDefined",
        "foo is not set");

    is(
        $exception->instance,
        $object,
        "foo is not set");

    is(
        $exception->attribute->name,
        "foo",
        "foo is not set");
}

{
    {
        package BadClass2;
        use Moose;

        has 'foo' => (
            is      => 'ro',
            handles => { get_count => 'count' }
        );
    }

    my $array = [12];
    my $object = BadClass2->new( foo => $array );
    my $exception = exception {
        $object->get_count;
    };

    like(
        $exception,
        qr/\QCannot delegate get_count to count because the value of foo is not an object (got '$array')/,
        "value of foo is an ARRAY ref");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeValueIsNotAnObject",
        "value of foo is an ARRAY ref");

    is(
        $exception->given_value,
        $array,
        "value of foo is an ARRAY ref");

    is(
        $exception->attribute->name,
        "foo",
        "value of foo is an ARRAY ref");
}

done_testing;
