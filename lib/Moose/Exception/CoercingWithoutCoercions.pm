package Moose::Exception::CoercingWithoutCoercions;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    my $self = shift;
    "Cannot coerce without a type coercion";
}
1;
