package Moose::Exception::DoesRequiresRoleName;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "You must supply a role name to does()";
}

1;
