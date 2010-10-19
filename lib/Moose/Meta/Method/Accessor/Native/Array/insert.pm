package Moose::Meta::Method::Accessor::Native::Array::insert;

use strict;
use warnings;

our $VERSION = '1.17';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::Writer' => {
    -excludes => [
        qw(
            _minimum_arguments
            _maximum_arguments
            _new_members
            _inline_optimized_set_new_value
            _return_value
            )
    ]
};

sub _minimum_arguments { 2 }

sub _maximum_arguments { 2 }

sub _adds_members { 1 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return
        "( do { my \@potential = \@{ ($slot_access) }; splice \@potential, \$_[0], 0, \$_[1]; \\\@potential } )";
}

sub _new_members { '$_[1]' }

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "splice \@{ ($slot_access) }, \$_[0], 0, \$_[1];";
}

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return "return ${slot_access}->[ \$_[0] ];";
}

no Moose::Role;

1;
