package Moose::Exception::SingleParamsToNewMustBeHRef;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "Single parameters to new() must be a HASH ref";
}

1;
