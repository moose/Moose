package Moose::Exception::CannotRegisterUnnamedTypeConstraint;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::TypeConstraint';

sub _build_message {
    "can't register an unnamed type constraint";
}

1;
