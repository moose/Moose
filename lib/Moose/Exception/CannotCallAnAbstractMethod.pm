package Moose::Exception::CannotCallAnAbstractMethod;
our $VERSION = '2.2208';

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "Abstract method";
}

__PACKAGE__->meta->make_immutable;
1;
