package Moose::Exception::ConstructClassInstanceTakesPackageName;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "You must pass a package name";
}

1;
