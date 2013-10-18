package Moose::Exception::MetaclassNotLoaded;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

sub _build_message {
    my $self = shift;
    "The Metaclass ".$self->class_name." must be loaded. (Perhaps you forgot to 'use ".$self->class_name."'?)";
}

1;
