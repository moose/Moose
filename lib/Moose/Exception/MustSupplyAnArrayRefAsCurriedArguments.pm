package Moose::Exception::MustSupplyAnArrayRefAsCurriedArguments;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    "You must supply a curried_arguments which is an ARRAY reference";
}

1;
