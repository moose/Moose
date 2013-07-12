package Moose::Exception::BadHasProvided;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    "Usage: has 'name' => ( key => value, ... )";
}

1;
