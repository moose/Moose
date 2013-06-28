package Moose::Exception::Role::InvalidAttributeOptions;

use Moose::Role;

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

1;
