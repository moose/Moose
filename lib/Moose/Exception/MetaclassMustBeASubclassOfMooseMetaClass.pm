package Moose::Exception::MetaclassMustBeASubclassOfMooseMetaClass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

sub _build_message {
    my $self = shift;
    "The Metaclass ".$self->class_name." must be a subclass of Moose::Meta::Class."
}

1;
