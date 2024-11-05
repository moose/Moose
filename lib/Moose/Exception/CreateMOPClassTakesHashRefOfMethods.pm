package Moose::Exception::CreateMOPClassTakesHashRefOfMethods;
our $VERSION = '3.0000';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::RoleForCreateMOPClass';

sub _build_message {
    "You must pass an HASH ref of methods";
}

__PACKAGE__->meta->make_immutable;
1;
