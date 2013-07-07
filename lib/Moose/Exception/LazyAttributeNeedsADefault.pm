package Moose::Exception::LazyAttributeNeedsADefault;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "You cannot have a lazy attribute (".$self->attribute_name.") without specifying a default value for it";
}

1;
