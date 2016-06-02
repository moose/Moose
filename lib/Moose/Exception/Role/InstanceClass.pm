package Moose::Exception::Role::InstanceClass;
our $VERSION = '2.1805';

use Moose::Role;

has 'instance_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
