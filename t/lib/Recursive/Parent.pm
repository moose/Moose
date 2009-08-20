package Recursive::Parent;
use Moose;

use Recursive::Child;

has child => (
    is  => 'ro',
    isa => 'Maybe[Recursive::Child]',
);

__PACKAGE__->meta->make_immutable;

1;
