#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    {
	package DoesTypeConstraintRole;
	use Moose;
	extends 'Moose::Exception';
	with 'Moose::Exception::Role::TypeConstraint';
    }

    my $exception = exception {
	my $doesTypeConstraintRole = DoesTypeConstraintRole->new;
    };

    like(
        $exception,
        qr/\QYou need to give type or type_name or both/,
	"please give either type or type_name");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherTypeNorTypeNameIsGiven",
	"please give either type or type_name");

    my $type = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint("foo");
    $exception = DoesTypeConstraintRole->new( type => $type );

    ok( !$exception->is_type_name_set, "type_name is not set");

    is(
    	$exception->type->name,
    	"foo",
    	"you have given type");

    is(
    	$exception->type_name,
    	"foo",
    	"you have given type");


    $exception = DoesTypeConstraintRole->new( type_name => "foo" );

    ok( !$exception->is_type_set, "type is not set");

    is(
    	$exception->type_name,
    	"foo",
    	"you have given type");

    is(
    	$exception->type->name,
    	"foo",
    	"you have given type");

    $exception = DoesTypeConstraintRole->new( type_name => "foo",
    				     type      => $type
                                   );

    is(
    	$exception->type_name,
    	"foo",
    	"you have given both, type & type_name");

    is(
    	$exception->type->name,
    	"foo",
    	"you have given both, type & type_name");

    $exception = exception {
        DoesTypeConstraintRole->new( type_name => "foo",
                                     type      => Moose::Util::TypeConstraints::find_or_create_isa_type_constraint("bar"),
                          );
    };

    like(
        $exception,
        qr/\Qtype_name (foo) does not match type->name (bar)/,
    	"you have given type_name as 'foo' and type->name as 'bar'");

    isa_ok(
        $exception,
        "Moose::Exception::TypeNamesDoNotMatch",
        "you have given type_name as 'foo' and type->name as 'bar'");

    is(
    	$exception->type_name,
    	"foo",
    	"you have given type_name as 'foo' and type->name as 'bar'");

    is(
    	$exception->type->name,
    	"bar",
    	"you have given type_name as 'foo' and type->name as 'bar'");
}

done_testing;
