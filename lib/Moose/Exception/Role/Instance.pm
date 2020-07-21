package Moose::Exception::Role::Instance;
our $VERSION = '2.2014';

use Moose::Role;

has 'instance' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

1;
