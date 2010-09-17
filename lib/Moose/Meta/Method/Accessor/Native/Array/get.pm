package Moose::Meta::Method::Accessor::Native::Array::get;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Reader';

sub _minimum_arguments { 1 }

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_check_var_is_valid_index('$_[0]');
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "${slot_access}->[ \$_[0] ]";
}

1;
