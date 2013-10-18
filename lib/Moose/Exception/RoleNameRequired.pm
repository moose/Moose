package Moose::Exception::RoleNameRequired;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

sub _build_message {
    "You must supply a role name to look for";
}

1;
