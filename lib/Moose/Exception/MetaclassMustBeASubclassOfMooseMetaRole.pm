package Moose::Exception::MetaclassMustBeASubclassOfMooseMetaRole;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

sub _build_message {
    my $self = shift;
    "The Metaclass ".$self->role_name." must be a subclass of Moose::Meta::Role."
}

1;
