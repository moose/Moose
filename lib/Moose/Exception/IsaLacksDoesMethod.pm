package Moose::Exception::IsaLacksDoesMethod;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "Cannot have an isa option which cannot ->does() on attribute (".$self->attribute_name.")";
}

1;
