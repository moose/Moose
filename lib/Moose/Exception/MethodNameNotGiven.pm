package Moose::Exception::MethodNameNotGiven;
our $VERSION = '2.1604';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

sub _build_message {
    "You must define a method name to find";
}

1;
