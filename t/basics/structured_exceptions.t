#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

{
    like( exception {
	package SubClassNoSuperClass;
	use Moose;
    	extends;
    	  } ,
    	  qr/Must derive at least one class/,
    	  "extends requires at least one argument" );

    isa_ok( exception {
	package SubClassNoSuperClass;
	use Moose;
    	extends;
    	  }, 
	    'Moose::Exception::ExtendsMissingArgs',
	    "extends requires at least one argument");
}

# tests for type coercions
{
    use Moose;
    use Moose::Util::TypeConstraints;
    subtype 'HexNum' => as 'Int', where { /[a-f0-9]/i };
    my $type_object = find_type_constraint 'HexNum';

    like(
        exception {
            $type_object->coerce;
        }, qr/Cannot coerce without a type coercion/,
        "You cannot coerce a type unless coercion is supported by that type");

    isa_ok(
        exception {
            $type_object->coerce;
        }, "Moose::Exception::CoercingWithoutCoercions",
        "You cannot coerce a type unless coercion is supported by that type");
}

# tests for type coercions
{
    use Moose;
    use Moose::Util::TypeConstraints;
    subtype 'HexNum' => as 'Int', where { /[a-f0-9]/i };
    my $type_object = find_type_constraint 'HexNum';

    my $exception = exception {
        $type_object->coerce;
    };

    like(
        $exception,
        qr/Cannot coerce without a type coercion/,
        "You cannot coerce a type unless coercion is supported by that type");

    like(
        $exception->type->name,
        qr/HexNum/,
        "You cannot coerce a type unless coercion is supported by that type");

    isa_ok(
        $exception,
        "Moose::Exception::CoercingWithoutCoercions",
        "You cannot coerce a type unless coercion is supported by that type");
}

done_testing;
