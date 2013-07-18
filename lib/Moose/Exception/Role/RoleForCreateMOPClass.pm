package Moose::Exception::Role::RoleForCreateMOPClass;

use Moose::Role;

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;

