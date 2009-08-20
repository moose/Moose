package Recursive::Child;
use Moose;
extends 'Recursive::Parent';

has parent => (
    is  => 'ro',
    isa => 'Recursive::Parent',
);

__PACKAGE__->meta->make_immutable;

1;
