package Moose::Exception::CannotRegisterUnnamedTypeConstraint;

use Moose;
extends 'Moose::Exception';

has 'type' => (
    is       => 'ro',
    isa      => 'Moose::Meta::TypeConstraint',
    required => 1,
);

sub _build_message {
    "can't register an unnamed type constraint";
}

1;
