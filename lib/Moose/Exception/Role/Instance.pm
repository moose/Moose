package Moose::Exception::Role::Instance;

use Moose::Role;

has 'instance' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

1;
