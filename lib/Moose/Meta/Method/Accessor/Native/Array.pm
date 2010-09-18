package Moose::Meta::Method::Accessor::Native::Array;

use strict;
use warnings;

use Scalar::Util qw( looks_like_number );

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native';

sub _inline_check_var_is_valid_index {
    my ( $self, $var ) = @_;

    return $self->_inline_throw_error( q{'The index passed to }
            . $self->delegate_to_method
            . q{ must be an integer'} )
        . qq{ unless defined $var && $var =~ /^-?\\d+\$/;};
}

1;
