package Moose::Meta::Method::Accessor::Native::Array::clear;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::Writer' => {
    -excludes => [
        qw(
            _maximum_arguments
            _inline_optimized_set_new_value
            _return_value
            )
    ]
};

sub _maximum_arguments { 0 }

sub _adds_members { 0 }

sub _potential_value { return '[]' }

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "$slot_access = []";
}

sub _return_value { return q{} }

no Moose::Role;

1;
