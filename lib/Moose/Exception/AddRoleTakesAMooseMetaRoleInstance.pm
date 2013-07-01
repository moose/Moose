package Moose::Exception::AddRoleTakesAMooseMetaRoleInstance;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "Roles must be instances of Moose::Meta::Role";
}

1;
