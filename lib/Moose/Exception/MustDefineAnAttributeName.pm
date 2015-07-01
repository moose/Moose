package Moose::Exception::MustDefineAnAttributeName;
our $VERSION = '2.1501'; # TRIAL

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

sub _build_message {
    "You must define an attribute name";
}

1;
