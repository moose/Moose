package Moose::Exception::CoercingWithoutCoercions;

use Moose;
use Moose::Exception;

extends 'Moose::Exception';

has 'type' => (
    is       => 'ro',
    isa      => "Moose::Meta::TypeConstraint",
    required => 1,
);

sub _build_message {
    my $self = shift;
    "Cannot coerce ".$self->type." without a type coercion";
}
1;
