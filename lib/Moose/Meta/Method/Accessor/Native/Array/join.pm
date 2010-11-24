package Moose::Meta::Method::Accessor::Native::Array::join;

use strict;
use warnings;

use Moose::Util ();

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader' => {
    -excludes => [
        qw(
            _minimum_arguments
            _maximum_arguments
            _inline_check_arguments
            )
    ]
};

sub _minimum_arguments { 1 }

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_throw_error(
        q{'The argument passed to join must be a string'})
        . ' unless Moose::Util::_STRINGLIKE0( $_[0] );';
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "join \$_[0], \@{ ($slot_access) }";
}

no Moose::Role;

1;
