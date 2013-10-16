package Moose::Exception::AddRoleToARoleTakesAMooseMetaRole;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

has 'role_to_be_added' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1,
);

sub _build_message {
    "Roles must be instances of Moose::Meta::Role";
}

1;
