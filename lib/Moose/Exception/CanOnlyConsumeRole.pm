package Moose::Exception::CanOnlyConsumeRole;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';

has 'role_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "You can only consume roles, ".$self->role_name." is not a Moose role";
}
1;
