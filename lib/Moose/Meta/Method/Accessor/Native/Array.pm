package Moose::Meta::Method::Accessor::Native::Array;

use strict;
use warnings;

use B;
use Scalar::Util qw( looks_like_number );

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native';

sub _value_needs_copy {
    my $self = shift;

    return @{ $self->curried_arguments };
}

sub _inline_copy_value {
    my $self = shift;

    return q{} unless $self->_value_needs_copy;

    my $curry = join ', ',
        map { looks_like_number($_) ? $_ : B::perlstring($_) }
        @{ $self->curried_arguments };

    return "my \@val = ( $curry, \@_ );";
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

1;
