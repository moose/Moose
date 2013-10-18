package Moose::Exception::NoImmutableTraitSpecifiedForClass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::ParamsHash';

sub _build_message {
    my $self = shift;
    "no immutable trait specified for ".$self->class;
}

1;
