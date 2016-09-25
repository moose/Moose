package Moose::Exception::NeitherRoleNorRoleNameIsGiven;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "You need to give role or role_name or both";
}

1;
