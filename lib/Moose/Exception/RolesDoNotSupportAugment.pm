package Moose::Exception::RolesDoNotSupportAugment;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "Roles cannot support 'augment'";
}

1;
