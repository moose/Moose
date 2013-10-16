package Moose::Exception::WrongTypeConstraintGiven;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has [qw/required_type given_type attribute_name/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "The type constraint for ".$self->attribute_name." must be a subtype of "
    .$self->required_type." but it's a ".$self->given_type;
}

1;
