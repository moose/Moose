package Moose::Exception::Role::Attribute;

use Moose::Role;

has 'attribute' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Attribute',
    required => 1,
);

1;
