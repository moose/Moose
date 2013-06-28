package Moose::Exception::InvalidValueForIs;

use Moose;
extends 'Moose::Exception';

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "I do not understand this option (is => ".$self->params->{is}.") on attribute (".$self->attribute_name.")";
}

1;
