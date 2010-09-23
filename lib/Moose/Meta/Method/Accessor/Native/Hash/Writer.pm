package Moose::Meta::Method::Accessor::Native::Hash::Writer;

use strict;
use warnings;

use Class::MOP::MiniTrait;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Writer';

Class::MOP::MiniTrait::apply( __PACKAGE__,
    'Moose::Meta::Method::Accessor::Native::Hash'
);
Class::MOP::MiniTrait::apply( __PACKAGE__,
    'Moose::Meta::Method::Accessor::Native::Collection'
);

sub _new_values {'@values'}

sub _inline_copy_old_value {
    my ( $self, $slot_access ) = @_;

    return '{ @{' . $slot_access . '} }';
}

1;
