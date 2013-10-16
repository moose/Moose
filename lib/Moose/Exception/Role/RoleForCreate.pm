package Moose::Exception::Role::RoleForCreate;

use Moose::Role;
with 'Moose::Exception::Role::ParamsHash';

has 'attribute_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;

