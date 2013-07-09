package Moose::Exception::RolesInCreateTakesAnArrayRef;

use Moose;
extends 'Moose::Exception';
   
has 'params' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "You must pass an ARRAY ref of roles";
}

1;
