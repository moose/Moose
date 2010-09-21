package Moose::Meta::Method::Accessor::Native::Array::shift;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _maximum_arguments { 0 }

sub _adds_members { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "[ \@{ $slot_access } > 1 ? \@{ $slot_access }[ 1 .. \$#{ $slot_access } ] : () ]";
}

sub _inline_capture_return_value {
    my ( $self, $slot_access ) = @_;

    return "my \$old = ${slot_access}->[0];";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "shift \@{ $slot_access };";
}

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return 'return $old';
}

1;
