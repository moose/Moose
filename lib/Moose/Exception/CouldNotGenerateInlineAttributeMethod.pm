package Moose::Exception::CouldNotGenerateInlineAttributeMethod;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Instance';

has [qw(error option)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);


sub _build_message {
    my $self = shift;
    "Could not generate inline ".$self->option." because : ".$self->error;
}

1;
