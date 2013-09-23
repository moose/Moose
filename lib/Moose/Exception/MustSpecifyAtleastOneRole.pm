package Moose::Exception::MustSpecifyAtleastOneRole;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

    
sub _build_message {
    "Must specify at least one role";
}

1;
