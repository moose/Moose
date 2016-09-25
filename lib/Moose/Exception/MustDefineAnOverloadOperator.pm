package Moose::Exception::MustDefineAnOverloadOperator;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Instance';

sub _build_message {
    "You must define an overload operator";
}

1;
