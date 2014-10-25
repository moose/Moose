package Moose::Exception::OverloadRequiresAMetaOverload;

use Moose;
extends 'Moose::Exception';

sub _build_message {
    my $self = shift;
    'If you provide an original_overload parameter to the Moose::Meta::Overload constructor it must be a Moose::Meta::Overload object';
}

1;
