package Moose::Exception::AutoDeRefNeedsArrayRefOrHashRef;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "You cannot auto-dereference anything other than a ArrayRef or HashRef on attribute (".$self->attribute_name.")";
}

1;
