package Moose::Exception::TypeConstraint;
use Moose;
extends 'Moose::Exception';

has attribute_name => (
    is  => 'ro',
    isa => 'Str',
);

has type_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has value => (
    is       => 'ro',
    required => 1,
);

has instance => (
    is  => 'ro',
    isa => 'Object',
);

1;

