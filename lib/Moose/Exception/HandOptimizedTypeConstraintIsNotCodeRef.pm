package Moose::Exception::HandOptimizedTypeConstraintIsNotCodeRef;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::TypeConstraint';

sub _build_message {
    my $self = shift;
    "Hand optimized type constraint is not a code reference";
}

1;
