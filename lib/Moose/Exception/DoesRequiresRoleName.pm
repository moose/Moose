package Moose::Exception::DoesRequiresRoleName;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

sub _build_message {
    "You must supply a role name to does()";
}

1;
