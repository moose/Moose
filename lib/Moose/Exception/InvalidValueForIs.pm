package Moose::Exception::InvalidValueForIs;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "I do not understand this option (is => ".$self->params->{is}.") on attribute (".$self->attribute_name.")";
}

1;
