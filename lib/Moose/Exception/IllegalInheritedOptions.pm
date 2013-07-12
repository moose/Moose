package Moose::Exception::IllegalInheritedOptions;

use Moose;
extends 'Moose::Exception';

has 'illegal_options' => (
    is       => 'ro',
    traits   => ['Array'],
    handles  => {
	_join_options => 'join',
    },
    required => 1,
);

has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "Illegal inherited options => (".$self->_join_options(', ').")";
}

1;
