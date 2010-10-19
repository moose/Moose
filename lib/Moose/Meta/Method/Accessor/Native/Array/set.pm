package Moose::Meta::Method::Accessor::Native::Array::set;

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
            _inline_check_arguments
            _new_members
            _inline_optimized_set_new_value
            _return_value
            )
    ]
};

sub _minimum_arguments { 2 }

sub _maximum_arguments { 2 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_check_var_is_valid_index('$_[0]');
}

sub _adds_members { 1 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return
        "( do { my \@potential = \@{ ($slot_access) }; \$potential[ \$_[0] ] = \$_[1]; \\\@potential } )";
}

sub _new_members { '$_[1]' }

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "${slot_access}->[ \$_[0] ] = \$_[1]";
}

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return "return ${slot_access}->[ \$_[0] ];";
}

no Moose::Role;

1;
