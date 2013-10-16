package Moose::Exception::CoercionNeedsTypeConstraint;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "You cannot have coercion without specifying a type constraint on attribute (".$self->attribute_name.")";
}

1;
