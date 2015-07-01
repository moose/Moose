package Moose::Exception::RolesDoNotSupportAugment;
our $VERSION = '2.1501'; # TRIAL

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "Roles cannot support 'augment'";
}

1;
