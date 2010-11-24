package Moose::Meta::Method::Accessor::Native::Hash;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

sub _inline_check_var_is_valid_key {
    my ( $self, $var ) = @_;

    return $self->_inline_throw_error( q{'The key passed to }
            . $self->delegate_to_method
            . q{ must be a defined value'} )
        . qq{ unless defined $var;};
}

no Moose::Role;

1;
