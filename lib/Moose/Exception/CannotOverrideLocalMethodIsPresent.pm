package Moose::Exception::CannotOverrideLocalMethodIsPresent;
our $VERSION = '3.0000';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::Method';

sub _build_message {
    "Cannot add an override method if a local method is already present";
}

__PACKAGE__->meta->make_immutable;
1;
