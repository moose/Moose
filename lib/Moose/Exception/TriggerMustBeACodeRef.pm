package Moose::Exception::TriggerMustBeACodeRef;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "Trigger must be a CODE ref on attribute (".$self->attribute_name.")";
}

1;
