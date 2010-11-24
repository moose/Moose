package Moose::Meta::Method::Accessor::Native::Array::sort;

use strict;
use warnings;

use Params::Util ();

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader' => {
    -excludes => [
        qw(
            _maximum_arguments
            _inline_check_arguments
            )
    ]
};

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_throw_error(
        q{'The argument passed to sort must be a code reference'})
        . q{ if @_ && ! Params::Util::_CODELIKE( $_[0] );};
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return
        "\$_[0] ? sort { \$_[0]->( \$a, \$b ) } \@{ ($slot_access) } : sort \@{ ($slot_access) }";
}

no Moose::Role;

1;
