package Moose::Exception::CannotCreateHigherOrderTypeWithoutATypeParameter;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::TypeConstraint';

sub _build_message {
    "You cannot create a Higher Order type without a type parameter";
}

1;
