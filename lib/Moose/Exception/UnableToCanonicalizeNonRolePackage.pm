package Moose::Exception::UnableToCanonicalizeNonRolePackage;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Attribute';

has 'handles' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "Unable to canonicalize the 'handles' option with ".$self->handles." because its metaclass is not a Moose::Meta::Role";
}

1;
