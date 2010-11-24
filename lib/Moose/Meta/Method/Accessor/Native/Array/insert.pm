package Moose::Meta::Method::Accessor::Native::Array::insert;

use strict;
use warnings;

our $VERSION = '1.21';
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

# We need to override this because while @_ can be written to, we cannot write
# directly to $_[1].
around _inline_coerce_new_values => sub {
    shift;
    my $self = shift;

    return q{} unless $self->associated_attribute->should_coerce;

    return q{} unless $self->_tc_member_type_can_coerce;

    return '@_ = ( $_[0], $member_tc_obj->coerce( $_[1] ) );';
};

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
