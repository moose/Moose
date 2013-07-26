package Moose::Exception::Role::Attribute;

use Moose::Role;

has 'attribute' => (
    is       => 'ro',
    isa      => 'Class::MOP::Attribute',
    required => 1,
);

1;
