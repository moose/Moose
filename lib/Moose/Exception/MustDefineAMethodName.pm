package Moose::Exception::MustDefineAMethodName;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Instance';

sub _build_message {
    "You must define a method name";
}

1;
