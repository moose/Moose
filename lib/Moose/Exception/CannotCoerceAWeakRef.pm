package Moose::Exception::CannotCoerceAWeakRef;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "You cannot have a weak reference to a coerced value on attribute (".$self->attribute_name.")";
}

1;
