package Moose::Meta::Method::Accessor::Native::Array::unshift;

use strict;
use warnings;

our $VERSION = '1.15';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::Writer' =>
    { -excludes => ['_inline_optimized_set_new_value'] };

sub _adds_members { 1 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "[ \@_, \@{ $slot_access } ]";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "unshift \@{ $slot_access }, \@_";
}

no Moose::Role;

1;
