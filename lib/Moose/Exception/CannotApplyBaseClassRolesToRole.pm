package Moose::Exception::CannotApplyBaseClassRolesToRole;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash', 'Moose::Exception::Role::Role';

sub _build_message {
    "You can only apply base class roles to a Moose class, not a role.";
}

1;
