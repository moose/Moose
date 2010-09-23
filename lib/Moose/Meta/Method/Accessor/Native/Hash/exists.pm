package Moose::Meta::Method::Accessor::Native::Hash::exists;

use strict;
use warnings;

use Scalar::Util qw( looks_like_number );

our $VERSION = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base qw(
    Moose::Meta::Method::Accessor::Native::Hash
    Moose::Meta::Method::Accessor::Native::Reader
);

sub _minimum_arguments { 1 }

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_check_var_is_valid_key('$_[0]');
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "exists ${slot_access}->{ \$_[0] }";
}


1;
