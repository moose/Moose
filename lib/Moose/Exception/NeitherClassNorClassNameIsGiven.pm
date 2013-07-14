package Moose::Exception::NeitherClassNorClassNameIsGiven;

use Moose;
extends 'Moose::Exception';
    
sub _build_message {
    "You need to give class or class_name or both";
}

1;
