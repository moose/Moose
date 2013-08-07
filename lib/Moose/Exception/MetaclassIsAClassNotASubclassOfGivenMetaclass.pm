package Moose::Exception::MetaclassIsAClassNotASubclassOfGivenMetaclass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has 'metaclass' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    $self->class_name." already has a metaclass, but it does not inherit ".$self->metaclass.' ('.$self->class.
	'). You cannot make the same thing a role and a class. Remove either Moose or Moose::Role.';
}

1;
