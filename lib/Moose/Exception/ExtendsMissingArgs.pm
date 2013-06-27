package Moose::Exception::ExtendsMissingArgs;

use Moose;
use Moose::Exception;

extends 'Moose::Exception';

sub _build_message {
    "Must derive at least one class";
}

1;
