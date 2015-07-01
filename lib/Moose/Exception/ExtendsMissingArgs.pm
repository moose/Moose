package Moose::Exception::ExtendsMissingArgs;
our $VERSION = '2.1501'; # TRIAL

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

sub _build_message {
    "Must derive at least one class";
}

1;
