package Moose::Exception::RoleDoesTheExcludedRole;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

has 'excluded_role' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Role',
    required => 1
);

has 'second_role' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Role',
    required => 1
);

sub _build_message {
    my $self = shift;
    "The role " . $self->role_name . " does the excluded role '".$self->excluded_role->name."'";
}

1;
