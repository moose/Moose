package Moose::Meta::Method::Accessor::Native::Array::delete;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _minimum_arguments { 1 }

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_check_var_is_valid_index('$_[0]');
}

sub _adds_members { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return
        "( do { my \@potential = \@{ $slot_access }; splice \@potential, \$_[0], 1; \@potential } )";
}

1;
