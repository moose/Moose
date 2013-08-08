package Moose::Exception::AttributeConflictInRoles;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

has 'second_role' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Role',
    required => 1
);

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "Role '". $self->role->name
    . "' has encountered an attribute conflict"
    . " while being composed into '".$self->second_role->name."'."
    . " This is a fatal error and cannot be disambiguated."
    . " The conflicting attribute is named '".$self->attribute_name."'.";
}

1;
