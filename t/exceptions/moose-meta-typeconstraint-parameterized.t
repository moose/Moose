
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    my $exception = exception {
        Moose::Meta::TypeConstraint::Parameterized->new( name => "TestType" );
    };

    like(
        $exception,
        qr/You cannot create a Higher Order type without a type parameter/,
        "type_parameter not given");

    isa_ok(
        $exception,
        'Moose::Exception::CannotCreateHigherOrderTypeWithoutATypeParameter',
        "type_parameter not given");

    is(
        $exception->type_name,
        "TestType",
        "type_parameter not given");
}

{
    my $exception = exception {
        Moose::Meta::TypeConstraint::Parameterized->new( name          => "TestType2",
                                                         type_parameter => 'Int'
                                                       );
    };

    like(
        $exception,
        qr/The type parameter must be a Moose meta type/,
        "'Int' is not a Moose::Meta::TypeConstraint");

    isa_ok(
        $exception,
        'Moose::Exception::TypeParameterMustBeMooseMetaType',
        "'Int' is not a Moose::Meta::TypeConstraint");

    is(
        $exception->type_name,
        "TestType2",
        "'Int' is not a Moose::Meta::TypeConstraint");
}

{
    my $exception = exception {
        package Foo;
        use Moose;

        has 'foo' => (
            is  => 'ro',
            isa => 'Int[Xyz]',
        );
    };

    like(
        $exception,
        qr/\QThe Int[Xyz] constraint cannot be used, because Int doesn't subtype or coerce from a parameterizable type./,
        "invalid isa given to foo");

    isa_ok(
        $exception,
        'Moose::Exception::TypeConstraintCannotBeUsedForAParameterizableType',
        "invalid isa given to foo");

    is(
        $exception->type_name,
        "Int[Xyz]",
        "invalid isa given to foo");

    is(
        $exception->parent_type_name,
        'Int',
        "invalid isa given to foo");
}

done_testing;
