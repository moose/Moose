package Moose::Exception::RequiredAttributeLacksInitialization;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    "A required attribute must have either 'init_arg', 'builder', or 'default'";
}

1;
