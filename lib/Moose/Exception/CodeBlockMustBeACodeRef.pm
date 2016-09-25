package Moose::Exception::CodeBlockMustBeACodeRef;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash', 'Moose::Exception::Role::Instance';

sub _build_message {
    "Your code block must be a CODE reference";
}

1;
