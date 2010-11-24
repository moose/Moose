package Moose::Meta::Method::Accessor::Native::Hash::Writer;

use strict;
use warnings;

use Class::MOP::MiniTrait;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer',
    'Moose::Meta::Method::Accessor::Native::Hash',
    'Moose::Meta::Method::Accessor::Native::Collection';

sub _new_values {'@values'}

sub _inline_copy_old_value {
    my ( $self, $slot_access ) = @_;

    return '{ %{(' . $slot_access . ')} }';
}

no Moose::Role;

1;
