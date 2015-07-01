package Moose::Exception::MustSpecifyAtleastOneMethod;
our $VERSION = '2.1501'; # TRIAL

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

sub _build_message {
    "Must specify at least one method";
}

1;
