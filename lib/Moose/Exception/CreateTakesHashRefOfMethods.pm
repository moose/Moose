package Moose::Exception::CreateTakesHashRefOfMethods;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::RoleForCreate';

sub _build_message {
    "You must pass a HASH ref of methods";
}

1;
