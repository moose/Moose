package Moose::Exception::Legacy;
our $VERSION = '3.0000';

use Moose;
extends 'Moose::Exception';

__PACKAGE__->meta->make_immutable;
1;
