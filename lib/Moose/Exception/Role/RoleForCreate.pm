package Moose::Exception::Role::RoleForCreate;

use Moose::Role;

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'attribute_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;

