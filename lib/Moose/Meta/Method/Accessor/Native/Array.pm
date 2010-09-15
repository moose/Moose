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

sub _inline_check_constraint {
    my $self = shift;

    return q{} unless $self->_constraint_must_be_checked;

    return $self->SUPER::_inline_check_constraint(@_);
}

sub _constraint_must_be_checked {
    my $self = shift;

    my $attr = $self->associated_attribute;

    return $attr->has_type_constraint
        && ( $attr->type_constraint->name ne 'ArrayRef'
        || ( $attr->should_coerce && $attr->type_constraint->has_coercion ) );
}

sub _inline_process_arguments { q{} }

sub _inline_check_arguments { q{} }

1;
