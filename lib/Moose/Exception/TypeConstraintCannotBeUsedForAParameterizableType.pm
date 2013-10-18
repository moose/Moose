package Moose::Exception::TypeConstraintCannotBeUsedForAParameterizableType;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::TypeConstraint';

sub _build_message {
    my $self = shift;
    "The " . $self->type_name . " constraint cannot be used, because "
    . $self->type->parent->name . " doesn't subtype or coerce from a parameterizable type."
}

1;
