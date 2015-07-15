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

my $MESSAGE = "Cannot assign a value to a read-only accessor";

sub _build_message {
    my $self = shift;
    return $MESSAGE unless $self->has_suggested_writer;
    return "$MESSAGE (did you mean to call the private writer?)"
        if $self->suggested_writer =~ /\A_/;
    return "$MESSAGE (did you mean to call the '".$self->suggested_writer."' writer?)";
}

1;
