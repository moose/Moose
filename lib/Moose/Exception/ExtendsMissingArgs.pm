package Moose::Exception::ExtendsMissingArgs;

use Moose;
use Moose::Exception;
use Devel::StackTrace;

extends 'Moose::Exception';

sub message {
    "Must derive at least one class";
}

1;
