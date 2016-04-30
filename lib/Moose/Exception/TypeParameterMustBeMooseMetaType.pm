package Moose::Exception::TypeParameterMustBeMooseMetaType;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::TypeConstraint';

sub _build_message {
    "The type parameter must be a Moose meta type";
}

1;
