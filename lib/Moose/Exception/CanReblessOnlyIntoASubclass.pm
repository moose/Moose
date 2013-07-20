package Moose::Exception::CanReblessOnlyIntoASubclass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::Instance';

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "You may rebless only into a subclass of (".blessed( $self->instance )."), of which (". $self->class->name .") isn't."
}

1;
