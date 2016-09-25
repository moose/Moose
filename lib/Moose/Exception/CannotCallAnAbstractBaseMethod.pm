package Moose::Exception::CannotCallAnAbstractBaseMethod;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';

has 'package_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    $self->package_name. " is an abstract base class, you must provide a constructor.";
}

1;
