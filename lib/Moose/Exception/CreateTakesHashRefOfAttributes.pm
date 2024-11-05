package Moose::Exception::CreateTakesHashRefOfAttributes;
our $VERSION = '3.0000';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::RoleForCreate';

sub _build_message {
    "You must pass a HASH ref of attributes";
}

__PACKAGE__->meta->make_immutable;
1;
