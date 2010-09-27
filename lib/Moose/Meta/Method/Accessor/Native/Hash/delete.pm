package Moose::Meta::Method::Accessor::Native::Hash::delete;

use strict;
use warnings;

our $VERSION = '1.15';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Hash::Writer' =>
    { -excludes => ['_inline_optimized_set_new_value'] };

sub _adds_members { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "( do { my \%potential = %{ $slot_access }; delete \@potential{\@_}; \\\%potential; } )";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "delete \@{ $slot_access }{\@_}";
}

no Moose::Role;

1;
