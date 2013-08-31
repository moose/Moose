package Moose::Exception::MustPassEvenNumberOfArguments;

use Moose;
extends 'Moose::Exception';

has 'args' => (
    is         => 'ro',
    isa        => 'ArrayRef',
    auto_deref => 1,
    required   => 1
);

has 'method_name' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1
);

sub _build_message {
    my $self = shift;
    "You must pass an even number of arguments to ".$self->method_name;
}

1;
