package Moose::Exception::Role::ParamsHash;
our $VERSION = '2.4001';

use Moose::Role;

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

1;
