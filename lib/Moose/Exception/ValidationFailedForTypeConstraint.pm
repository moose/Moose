package Moose::Exception::ValidationFailedForTypeConstraint;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Attribute', 'Moose::Exception::Role::TypeConstraint';

has 'value' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1,
);

sub _build_message {
    my $self = shift;

    my $error_message = $self->type->get_message($self->value);

    if( $self->is_attribute_set )
    {
        return "Attribute (". $self->attribute->name. ") does not pass the type constraint because: ".$error_message;
    }

    return $error_message;
}

1;
