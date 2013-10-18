package Moose::Exception::CreateMOPClassTakesArrayRefOfAttributes;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::RoleForCreateMOPClass';

sub _build_message {
    "You must pass an ARRAY ref of attributes";
}

1;
