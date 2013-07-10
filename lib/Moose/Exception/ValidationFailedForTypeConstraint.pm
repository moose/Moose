package Moose::Exception::ValidationFailedForTypeConstraint;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Attribute';

has 'type_constraint' => (
    is       => 'ro',
    isa      => 'Moose::Meta::TypeConstraint',
    required => 1,
);

has 'value' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "Attribute (". $self->attribute->name. ") does not pass the type constraint because: ".$self->type_constraint->get_message($self->value);
}

1;
