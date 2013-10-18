#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util 'throw_exception';

{
    {
        package TestClass;
        use Moose;

        has 'foo' => (
            is       => 'ro',
            isa      => 'Int',
            required => 1
        );
    }

    my $exception = exception {
        throw_exception( AttributeIsRequired => attribute_name => 'foo' );
    };

    like(
        $exception,
        qr/You need to give class or class_name or both/,
        "please give either class or class_name");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherClassNorClassNameIsGiven",
        "please give either class or class_name");

    $exception = exception {
        throw_exception( AttributeIsRequired => class_name => 'TestClass' );
    };

    like(
        $exception,
        qr/You need to give attribute or attribute_name or both/,
        "please give either attribute or attribute_name");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherAttributeNorAttributeNameIsGiven",
        "please give either class or class_name");

    $exception = exception {
        throw_exception( AttributeIsRequired => attribute_name => 'foo1',
                                                attribute      => TestClass->meta->get_attribute("foo")
                       );
    };

    like(
        $exception,
        qr/\Qattribute_name (foo1) does not match attribute->name (foo)/,
        "attribute->name & attribute_name do not match");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeNamesDoNotMatch",
        "attribute->name & attribute_name do not match");

    is(
        $exception->attribute_name,
        "foo1",
        "attribute->name & attribute_name do not match");

    is(
        $exception->attribute->name,
        "foo",
        "attribute->name & attribute_name do not match");

    $exception = exception {
        throw_exception( AttributeIsRequired => attribute => TestClass->meta->get_attribute("foo")
                       );
    };

    like(
        $exception,
        qr/\QAttribute (foo) is required/,
        "since, attribute is given, so we should get AttributeIsRequired");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeIsRequired",
        "since, attribute is given, so we should get AttributeIsRequired");

    is(
        $exception->attribute_name,
        "foo",
        "since, attribute is given, so we should get AttributeIsRequired");

    is(
        $exception->attribute->name,
        "foo",
        "since, attribute is given, so we should get AttributeIsRequired");

    is(
        $exception->class_name,
        "TestClass",
        "since, attribute is given, so we should get AttributeIsRequired");

    is(
        $exception->class,
        TestClass->meta,
        "since, attribute is given, so we should get AttributeIsRequired");

    $exception = exception {
        throw_exception( AttributeIsRequired => class_name => 'TestClass1',
                                                class      => TestClass->meta
                       );
    };

    like(
        $exception,
        qr/You need to give attribute or attribute_name or both/,
        "neither attribute, nor attribute_mame is given");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherAttributeNorAttributeNameIsGiven",
        "neither attribute, nor attribute_mame is given");

    $exception = exception {
        throw_exception( AttributeIsRequired => attribute  => TestClass->meta->get_attribute("foo"),
                                                class_name => "TestClass1"
                       );
    };

    like(
        $exception,
        qr/\Qclass_name (TestClass1) does not match class->name (TestClass)/,
        "class names do not match");

    isa_ok(
        $exception,
        "Moose::Exception::ClassNamesDoNotMatch",
        "class names do not match");

    is(
        $exception->class_name,
        "TestClass1",
        "class names do not match");

    is(
        $exception->class,
        TestClass->meta,
        "class names do not match");
}

done_testing;
