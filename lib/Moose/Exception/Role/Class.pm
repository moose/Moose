package Moose::Exception::Role::Class;

use Moose::Role;

has 'class' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Class',
    required => 1,
);

1;
