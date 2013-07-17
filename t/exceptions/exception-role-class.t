#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

{
    {
	package DoesClassRole;
	use Moose;
	extends 'Moose::Exception';
	with 'Moose::Exception::Role::Class';
    }

    my $exception = exception {
	my $doesClassRole = DoesClassRole->new;
    };

    like(
        $exception,
        qr/\QYou need to give class or class_name or both/,
	"please give either class or class_name");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherClassNorClassNameIsGiven",
        "please give either class or class_name");

    {
	package JustATestClass;
	use Moose;
    }

    $exception = DoesClassRole->new( class => JustATestClass->meta );

    ok( !$exception->is_class_name_set, "class_name is not set");

    is(
	$exception->class->name,
	"JustATestClass",
	"you have given class");

    is(
	$exception->class_name,
	"JustATestClass",
	"you have given class");

    $exception = DoesClassRole->new( class_name => "JustATestClass" );

    ok( !$exception->is_class_set, "class is not set");

    is(
	$exception->class_name,
	"JustATestClass",
	"you have given class");

    is(
	$exception->class->name,
	"JustATestClass",
	"you have given class");

    $exception = DoesClassRole->new( class_name => "DoesClassRole",
				     class      => DoesClassRole->meta
                                   );

    is(
	$exception->class_name,
	"DoesClassRole",
	"you have given both, class & class_name");

    is(
	$exception->class->name,
	"DoesClassRole",
	"you have given both, class & class_name");

    $exception = exception {
        DoesClassRole->new( class_name => "Foo",
                            class      => DoesClassRole->meta,
                          );
    };

    like(
        $exception,
        qr/\Qclass_name (Foo) does not match class->name (DoesClassRole)/,
	"you have given class_name as 'Foo' and class->name as 'DoesClassRole'");

    isa_ok(
        $exception,
        "Moose::Exception::ClassNamesDoNotMatch",
        "you have given class_name as 'Foo' and class->name as 'DoesClassRole'");

    is(
	$exception->class_name,
	"Foo",
	"you have given class_name as 'Foo' and class->name as 'DoesClassRole'");

    is(
	$exception->class->name,
	"DoesClassRole",
	"you have given class_name as 'Foo' and class->name as 'DoesClassRole'");
}

done_testing;