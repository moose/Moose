package Moose::Exception::ClassNamesDoNotMatch;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';

has class_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has class => (
    is       => 'ro',
    isa      => 'Class::MOP::Class',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "class_name (".$self-> class_name.") does not match class->name (".$self->class->name.")";
}

1;
