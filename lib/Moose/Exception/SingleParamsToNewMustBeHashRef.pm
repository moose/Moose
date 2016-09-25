package Moose::Exception::SingleParamsToNewMustBeHashRef;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "Single parameters to new() must be a HASH ref";
}

1;
