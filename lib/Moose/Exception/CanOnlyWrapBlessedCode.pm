package Moose::Exception::CanOnlyWrapBlessedCode;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'code' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

sub _build_message {
    "Can only wrap blessed CODE";
}

1;
