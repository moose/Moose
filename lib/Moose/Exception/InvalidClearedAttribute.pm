package Moose::Exception::InvalidClearedAttribute;
our $VERSION = '2.2013';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "You said clear_" . $self->attribute_name . " but " . $self->attribute_name
        . " is not the name of an existing attribute";
}

__PACKAGE__->meta->make_immutable;
1;
