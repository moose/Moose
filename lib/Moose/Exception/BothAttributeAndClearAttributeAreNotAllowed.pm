package Moose::Exception::BothAttributeAndClearAttributeAreNotAllowed;
our $VERSION = '2.2013';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    return "You said both to clear_" . $self->attribute_name
        . " and also to set a value for " . $self->attribute_name;
}

__PACKAGE__->meta->make_immutable;
1;
