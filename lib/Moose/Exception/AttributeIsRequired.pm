package Moose::Exception::AttributeIsRequired;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Attribute', 'Moose::Exception::Role::Instance';

has 'params' => (
    is  => 'ro',
    isa => 'HashRef'
);

sub _build_message {
    my $self = shift;
    "Attribute (".$self->attribute->name.") is required";
}

1;
