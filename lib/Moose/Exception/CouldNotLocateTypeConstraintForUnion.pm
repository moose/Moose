package Moose::Exception::CouldNotLocateTypeConstraintForUnion;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::TypeConstraint';

sub _build_message {
    my $self = shift;
    "Could not locate type constraint (".$self->type_name.") for the union";
}

1;
