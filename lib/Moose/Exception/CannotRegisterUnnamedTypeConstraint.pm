package Moose::Exception::CannotRegisterUnnamedTypeConstraint;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "can't register an unnamed type constraint";
}

1;
