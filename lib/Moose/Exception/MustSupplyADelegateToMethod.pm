package Moose::Exception::MustSupplyADelegateToMethod;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    "You must supply a delegate_to_method which is a method name or a CODE reference";
}

1;
