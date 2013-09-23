package Moose::Exception::IsaDoesNotDoTheRole;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "Cannot have an isa option and a does option if the isa does not do the does on attribute (".$self->attribute_name.")";
}

1;
