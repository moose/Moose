package Moose::Exception::Role::InstanceClass;
our $VERSION = '3.0000';

use Moose::Role;

has 'instance_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
