package Moose::Exception::MustDefineAnOverloadOperator;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Instance';

sub _build_message {
    "You must define an overload operator";
}

1;
