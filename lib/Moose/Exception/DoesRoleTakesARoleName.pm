package Moose::Exception::DoesRoleTakesARoleName;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "You must supply a role name to look for";
}

1;
