package Moose::Exception::Role::AttributeName;
our $VERSION = '3.0000';

use Moose::Role;

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

1;
