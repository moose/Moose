package Moose::Exception::Legacy;
our $VERSION = '2.4001';

use Moose;
extends 'Moose::Exception';

__PACKAGE__->meta->make_immutable;
1;
