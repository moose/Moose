package Moose::Exception::NoConstraintCheckForTypeConstraint;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::TypeConstraint';

sub _build_message {
    my $self = shift;
    "Could not compile type constraint '".$self->type_name."' because no constraint check";
}

1;
