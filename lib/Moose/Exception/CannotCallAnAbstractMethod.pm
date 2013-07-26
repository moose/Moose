package Moose::Exception::CannotCallAnAbstractMethod;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "Abstract method";
}

1;
