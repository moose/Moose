package Moose::Exception::MethodNameNotGiven;

use Moose;
extends 'Moose::Exception';

has 'class' => (
    is       => 'ro',
    isa      => 'Class::MOP::Class',
    required => 1
);

sub _build_message {
    "You must define a method name to find";
}

1;
