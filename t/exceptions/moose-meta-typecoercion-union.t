
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose;
use Moose::Util::TypeConstraints;

{
    my $exception = exception {
        Moose::Meta::TypeCoercion::Union->new( type_constraint => find_type_constraint("Str") );
    };

    like(
        $exception,
        qr/\QYou can only create a Moose::Meta::TypeCoercion::Union for a Moose::Meta::TypeConstraint::Union, not a Str/,
        "'Str' is not a Moose::Meta::TypeConstraint::Union");

    isa_ok(
        $exception,
        "Moose::Exception::NeedsTypeConstraintUnionForTypeCoercionUnion",
        "'Str' is not a Moose::Meta::TypeConstraint::Union");

    is(
        $exception->type_name,
        "Str",
        "'Str' is not a Moose::Meta::TypeConstraint::Union");
}

{
    union 'StringOrInt', [qw( Str Int )];
    my $type = find_type_constraint("StringOrInt");
    my $tt = Moose::Meta::TypeCoercion::Union->new( type_constraint => $type );

    my $exception = exception {
        $tt->add_type_coercions("ArrayRef");
    };

    like(
        $exception,
        qr/Cannot add additional type coercions to Union types/,
        "trying to add ArrayRef to a Moose::Meta::TypeCoercion::Union object");

    isa_ok(
        $exception,
        "Moose::Exception::CannotAddAdditionalTypeCoercionsToUnion",
        "trying to add ArrayRef to a Moose::Meta::TypeCoercion::Union object");

    is(
        $exception->type_coercion_union_object,
        $tt,
        "trying to add ArrayRef to a Moose::Meta::TypeCoercion::Union object");
}

done_testing;
