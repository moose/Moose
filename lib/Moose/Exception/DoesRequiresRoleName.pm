package Moose::Exception::DoesRequiresRoleName;

use Moose;
extends 'Moose::Exception';

has 'object' => (
    is       => 'ro',
    isa      => 'Moose::Object',
    required => 1,
);

sub _build_message {
    "You must supply a role name to does()";
}

1;
