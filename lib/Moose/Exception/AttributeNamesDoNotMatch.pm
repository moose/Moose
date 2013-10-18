package Moose::Exception::AttributeNamesDoNotMatch;

use Moose;
extends 'Moose::Exception';

has attribute_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has attribute => (
    is       => 'ro',
    isa      => 'Class::MOP::Attribute',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "attribute_name (".$self-> attribute_name.") does not match attribute->name (".$self->attribute->name.")";
}

1;
