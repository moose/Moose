package Moose::Meta::Method::Accessor::Native::Array::sort_in_place;

use strict;
use warnings;

use Params::Util ();

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::Writer' => {
    -excludes => [
        qw(
            _maximum_arguments
            _inline_check_arguments
            _return_value
            )
    ]
};

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_throw_error(
        q{'The argument passed to sort_in_place must be a code reference'})
        . q{ if @_ && ! Params::Util::_CODELIKE( $_[0] );};
}

sub _adds_members { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return
        "[ \$_[0] ? sort { \$_[0]->( \$a, \$b ) } \@{ ($slot_access) } : sort \@{ ($slot_access) } ]";
}

sub _return_value { return q{} }

no Moose::Role;

1;
