package Moose::Exception::InvalidOverloadOperator;

use Moose;
extends 'Moose::Exception';

has operator => (
    is       => 'ro',
    isa      => 'Defined',
    required => 1,
);

sub _build_message {
    my $self = shift;
    'The operator parameter you passed to the Moose::Meta::Overload constructor ('
        . $self->operator()
        . ') was not a valid overloading operator';
}

1;
