package Moose::Exception::IncompatibleMetaclassOfSuperclass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has [qw/superclass_name superclass_meta_type/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "The metaclass of " . $self->class_name . " ("
    . (ref($self->class)) . ")" .  " is not compatible with "
    . "the metaclass of its superclass, "
    . $self->superclass_name . " (" . ($self->superclass_meta_type) . ")";
}

1;
