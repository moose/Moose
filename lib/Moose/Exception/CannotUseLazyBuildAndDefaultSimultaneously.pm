package Moose::Exception::CannotUseLazyBuildAndDefaultSimultaneously;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "You can not use lazy_build and default for the same attribute (".$self->attribute_name.")";
}

1;
