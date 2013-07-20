package Moose::Exception::InstanceBlessedIntoWrongClass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::Instance';

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1
);

sub _build_message {
    my $self = shift;
    "Objects passed as the __INSTANCE__ parameter must already be blessed into the correct class, but ".$self->instance." is not a " . $self->class->name;
}

1;
