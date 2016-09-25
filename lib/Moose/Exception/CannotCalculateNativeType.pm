package Moose::Exception::CannotCalculateNativeType;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Instance';

sub _build_message {
    my $self = shift;
    "Cannot calculate native type for " . ref $self->instance;
}

1;
