package Moose::Exception::Role::ParamsHash;
our $VERSION = '3.0000';

use Moose::Role;

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

1;
