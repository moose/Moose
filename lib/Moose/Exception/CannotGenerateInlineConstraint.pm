package Moose::Exception::CannotGenerateInlineConstraint;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::TypeConstraint';

has 'parameterizable_type_object' => (
    is       => 'ro',
    isa      => 'Moose::Meta::TypeConstraint::Parameterizable',
    required => 1
);

has 'value' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    my $type = $self->type;

    return "Can't generate an inline constraint for $type, since none was defined";
}

1;
