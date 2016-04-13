package Moose::Exception::Role::AttributeName;
our $VERSION = '2.1705';

use Moose::Role;

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

1;
