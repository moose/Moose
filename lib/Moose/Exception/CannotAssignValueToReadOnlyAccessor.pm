package Moose::Exception::CannotAssignValueToReadOnlyAccessor;
our $VERSION = '2.1501';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::EitherAttributeOrAttributeName';

has 'value' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

has 'suggested_writer' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_suggested_writer',
);

sub _build_message {
    my $self = shift;
    return "Cannot assign a value to a read-only accessor"
        unless $self->has_suggested_writer;
    return "Cannot assign a value to a read-only accessor (did you mean to call the '".$self->suggested_writer."' writer?)";
}

1;
