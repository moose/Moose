package Moose::Meta::Method::Accessor::Native::Array::push;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::Writer' => {
    -excludes => [
        qw(
            _inline_optimized_set_new_value
            _return_value
            )
    ]
};

sub _adds_members { 1 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "[ \@{ ($slot_access) }, \@_ ]";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "push \@{ ($slot_access) }, \@_";
}

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return "return scalar \@{ ($slot_access) }";
}

no Moose::Role;

1;
