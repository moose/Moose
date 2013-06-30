package Moose::Exception::BuilderDoesNotExist;

use Moose;
extends 'Moose::Exception';

has 'instance' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

has 'attribute' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Attribute',
    required => 1,
);

sub _build_message {
    my $self = shift;
    blessed($self->instance)." does not support builder method '".$self->attribute->builder."' for attribute '".$self->attribute->name."'";
}

1;
