package Moose::Exception::DoesRequiresRoleName;

use Moose;
extends 'Moose::Exception';

has 'class' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Class',
    required => 1,
);

sub _build_message {
    "You must supply a role name to does()";
}

1;
