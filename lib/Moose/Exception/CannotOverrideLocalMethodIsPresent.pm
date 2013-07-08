package Moose::Exception::CannotOverrideLocalMethodIsPresent;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::Method';

sub _build_message {
    "Cannot add an override method if a local method is already present";
}

1;
