package Moose::Exception::InitMetaRequiresClass;

use Moose;
extends 'Moose::Exception';

has 'args' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub _build_message {
    "Cannot call init_meta without specifying a for_class";
}

1;
