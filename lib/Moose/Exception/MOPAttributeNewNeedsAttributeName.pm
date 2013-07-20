package Moose::Exception::MOPAttributeNewNeedsAttributeName;

use Moose;
extends 'Moose::Exception';

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1
);

sub _build_message {
    "You must provide a name for the attribute";
}

1;
