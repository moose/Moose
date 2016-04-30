package Moose::Exception::RoleNameRequiredForMooseMetaRole;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

sub _build_message {
    "You must supply a role name to look for";
}

1;
