package Moose::Exception::InvalidNameForType;

use Moose;
use Moose::Exception;

extends 'Moose::Exception';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;
    $self->name." contains invalid characters for a type name. Names can contain alphanumeric character, ':', and '.'";
}
1;
