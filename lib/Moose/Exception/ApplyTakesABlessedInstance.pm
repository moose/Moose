package Moose::Exception::ApplyTakesABlessedInstance;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

has 'param' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1,
);

sub _build_message {
    "You must pass in an blessed instance";
}

1;
