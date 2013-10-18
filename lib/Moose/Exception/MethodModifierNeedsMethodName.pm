package Moose::Exception::MethodModifierNeedsMethodName;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

sub _build_message {
    "You must pass in a method name";
}

1;
