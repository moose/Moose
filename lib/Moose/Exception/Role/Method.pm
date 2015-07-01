package Moose::Exception::Role::Method;
our $VERSION = '2.1501'; # TRIAL

use Moose::Role;

has 'method' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Method',
    required => 1,
);

1;
