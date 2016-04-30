package Moose::Exception::RolesDoNotSupportExtends;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "Roles do not support 'extends' (you can use 'with' to specialize a role)";
}

1;
