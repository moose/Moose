package Moose::Meta::Method::Accessor::Native::Array::Writer;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer',
    'Moose::Meta::Method::Accessor::Native::Array',
    'Moose::Meta::Method::Accessor::Native::Collection';

sub _new_members {'@_'}

sub _inline_copy_old_value {
    my ( $self, $slot_access ) = @_;

    return '[ @{(' . $slot_access . ')} ]';
}

1;
