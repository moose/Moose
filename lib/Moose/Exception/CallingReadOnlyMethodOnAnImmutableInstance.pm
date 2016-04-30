package Moose::Exception::CallingReadOnlyMethodOnAnImmutableInstance;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';

has 'method_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "The '".$self->method_name."' method is read-only when called on an immutable instance";
}

1;
