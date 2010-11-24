package Moose::Meta::Method::Accessor::Native::Hash::delete;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Hash::Writer' => {
    -excludes => [
        qw(
            _inline_optimized_set_new_value
            _return_value
            )
    ],
};

sub _adds_members { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "( do { my \%potential = %{ ($slot_access) }; \@return = delete \@potential{\@_}; \\\%potential; } )";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "\@return = delete \@{ ($slot_access) }{\@_}";
}

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return 'return wantarray ? @return : $return[-1];';
}

no Moose::Role;

1;
