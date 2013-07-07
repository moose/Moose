package Moose::Exception::CannotAugmentIfLocalMethodPresent;

use Moose;
extends 'Moose::Exception';

has 'class' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Class',
    required => 1,
);

has 'method' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Method',
    required => 1,
);

sub _build_message {
    "Cannot add an augment method if a local method is already present";
}

1;
