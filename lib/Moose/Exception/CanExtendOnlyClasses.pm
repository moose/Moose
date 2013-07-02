package Moose::Exception::CanExtendOnlyClasses;

use Moose;
extends 'Moose::Exception';

has 'role' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Role',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "You cannot inherit from a Moose Role (".$self->role->name.")";
}

1;
