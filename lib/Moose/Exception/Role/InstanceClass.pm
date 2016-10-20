package Moose::Exception::Role::InstanceClass;
our $VERSION = '2.1902';

use Moose::Role;

has 'instance_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
