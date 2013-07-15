package Moose::Exception::MustSpecifyAtleastOneMethod;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

sub _build_message {
    "Must specify at least one method";
}

1;
