package Moose::Exception::CannotAddAdditionalTypeCoercionsToUnion;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';

has 'type_coercion_union_object' => (
    is       => 'ro',
    isa      => 'Moose::Meta::TypeCoercion::Union',
    required => 1
);

sub _build_message {
    return "Cannot add additional type coercions to Union types";
}

1;
