package Moose::Exception::MethodExpectedAMetaclassObject;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'metaclass' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

sub _build_message {
    "The is_needed method expected a metaclass object as its arugment";
}

1;
