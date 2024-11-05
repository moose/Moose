package Moose::Exception::CannotApplyBaseClassRolesToRole;
our $VERSION = '3.0000';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash', 'Moose::Exception::Role::Role';

sub _build_message {
    "You can only apply base class roles to a Moose class, not a role.";
}

__PACKAGE__->meta->make_immutable;
1;
