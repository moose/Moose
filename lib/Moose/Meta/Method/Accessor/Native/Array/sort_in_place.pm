package Moose::Meta::Method::Accessor::Native::Array::sort_in_place;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_throw_error(
        q{'The argument passed to sort_in_place must be a code reference'})
        . q{if $_[0] && ( ref $_[0] || q{} ) ne 'CODE';};
}

sub _adds_members { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return
        "[ \$_[0] ? sort { \$_[0]->( \$a, \$b ) } \@{ $slot_access } : sort \@{ $slot_access} ]";
}

1;
