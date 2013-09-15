package Moose::Exception::MustSupplyArrayRefAsCurriedArguments;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash', 'Moose::Exception::Role::Class';

sub _build_message {
    "You must supply a curried_arguments which is an ARRAY reference";
}

1;
