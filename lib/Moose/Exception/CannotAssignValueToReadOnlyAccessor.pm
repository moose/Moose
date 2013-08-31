package Moose::Exception::CannotAssignValueToReadOnlyAccessor;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has 'value' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "Cannot assign a value to a read-only accessor";
}

1;
