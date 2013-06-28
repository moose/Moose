package Moose::Exception::AttributeIsRequired;

use Moose;
extends 'Moose::Exception';

has 'attribute' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Attribute',
    required => 1,
);

has 'instance' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);
    
has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "Attribute (".$self->attribute->name.") is required";
}

1;
