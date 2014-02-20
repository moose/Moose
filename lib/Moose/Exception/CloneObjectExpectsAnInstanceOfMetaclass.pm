package Moose::Exception::CloneObjectExpectsAnInstanceOfMetaclass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has 'instance' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "You must pass an instance of the metaclass (" .$self->class_name. "), not (".$self->instance.")";
}

1;
