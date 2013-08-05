package Moose::Exception::ValidationFailedForInlineTypeConstraint;
 
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has 'type_constraint_message' => (
    is  => 'ro',
    isa => 'Str',
    required => 1
);

has 'attribute_name' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);
 
has 'value' => (
    is => 'ro',
    isa => 'Any',
    required => 1
);
 
sub _build_message {
    my $self = shift;

    "Attribute (".$self->attribute_name.") does not pass the type constraint because: ".$self->type_constraint_message;
}
 
1;
