package Moose::Meta::Method::Accessor::Native::Hash::get;

use strict;
use warnings;

use Scalar::Util qw( looks_like_number );

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Reader';

Class::MOP::MiniTrait::apply( __PACKAGE__,
    'Moose::Meta::Method::Accessor::Native::Hash'
);

sub _minimum_arguments { 1 }

sub _maximum_arguments { undef }

sub _inline_check_arguments {
    my $self = shift;

    return
        'for (@_) {' . "\n"
        . $self->_inline_check_var_is_valid_key('$_') . "\n" . '}';
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "\@_ > 1 ? \@{ $slot_access }{\@_} : ${slot_access}->{ \$_[0] }";
}


1;
