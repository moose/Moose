package Moose::Meta::Method::Accessor::Native::Array;

use strict;
use warnings;

use B;
use Scalar::Util qw( looks_like_number );

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native';

sub _inline_curried_arguments {
    my $self = shift;

    return q{} unless @{ $self->curried_arguments };

    return 'unshift @_, @curried;'
}

sub _inline_check_argument_count {
    my $self = shift;

    my $code = q{};

    if ( my $min = $self->_minimum_arguments ) {
        my $err_msg = sprintf(
            q{"Cannot call %s without at least %s argument%s"},
            $self->delegate_to_method,
            $min,
            ( $min == 1 ? q{} : 's' )
        );

        $code
            .= "\n"
            . $self->_inline_throw_error($err_msg)
            . " unless \@_ >= $min;";
    }

    if ( defined( my $max = $self->_maximum_arguments ) ) {
        my $err_msg = sprintf(
            q{"Cannot call %s with %s argument%s"},
            $self->delegate_to_method,
            ( $max ? "more than $max" : 'any' ),
            ( $max == 1 ? q{} : 's' )
        );

        $code
            .= "\n"
            . $self->_inline_throw_error($err_msg)
            . " if \@_ > $max;";
    }

    return $code;
}

sub _minimum_arguments { 0 }
sub _maximum_arguments { undef }

sub _inline_check_arguments { q{} }

sub _inline_check_var_is_valid_index {
    my ( $self, $var ) = @_;

    return
        qq{die 'Must provide a valid index number as an argument' unless defined $var && $var =~ /^-?\\d+\$/;};
}

1;
