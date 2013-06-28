package Moose::Exception::AccessorMustReadWrite;

use Moose;
use Moose::Exception;

extends 'Moose::Exception';

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "Cannot define an accessor name on a read-only attribute, accessors are read/write";
}

1;
