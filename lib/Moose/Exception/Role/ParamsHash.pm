package Moose::Exception::Role::ParamsHash;
our $VERSION = '2.2012';

use Moose::Role;

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

1;
