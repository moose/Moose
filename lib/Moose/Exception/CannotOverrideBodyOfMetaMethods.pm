package Moose::Exception::CannotOverrideBodyOfMetaMethods;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    "Overriding the body of meta methods is not allowed";
}

1;
