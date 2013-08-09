package Moose::Exception::OverrideMethodConflictInRoleComposition;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

has 'role_being_applied' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Role',
    required => 1
);

has 'method_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "Role '" . $self->role_being_applied->name . "' has encountered an 'override' method conflict " .
        "during composition (A local method of the same name as been found). This " .
        "is a fatal error."
}

1;
