package Moose::Exception::Role::Instance;
our $VERSION = '3.0000';

use Moose::Role;

has 'instance' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

1;
