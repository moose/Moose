package Moose::Meta::Method::Accessor::Native::Bool::toggle;

use strict;
use warnings;

our $VERSION = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Writer';

sub _minimum_arguments { 0 }
sub _maximum_arguments { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "$slot_access ? 0 : 1;";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "$slot_access = $slot_access ? 0 : 1;";
}

1;
