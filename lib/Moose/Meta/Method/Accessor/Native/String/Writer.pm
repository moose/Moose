package Moose::Meta::Method::Accessor::Native::String::Writer;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base qw(
    Moose::Meta::Method::Accessor::Native::String
    Moose::Meta::Method::Accessor::Native::Writer
);

sub _new_value {'$_[0]'}

sub _inline_copy_value {
    my ( $self, $potential_ref ) = @_;

    return q{} unless $self->_value_needs_copy;

    my $code = "my \$potential = ${$potential_ref};";

    ${$potential_ref} = '$potential';

    return $code;
}

sub _value_needs_copy {
    my $self = shift;

    return $self->_constraint_must_be_checked;
}

sub _inline_tc_code {
    my ( $self, $new_value, $potential_value ) = @_;

    return q{} unless $self->_constraint_must_be_checked;

    return $self->_inline_check_coercion($potential_value) . "\n"
        . $self->_inline_check_constraint($potential_value);
}

sub _constraint_must_be_checked {
    my $self = shift;

    my $attr = $self->associated_attribute;

    return $attr->has_type_constraint
        && ( $attr->type_constraint->name ne 'Str'
        || ( $attr->should_coerce && $attr->type_constraint->has_coercion ) );
}

sub _inline_check_coercion {
    my ( $self, $value ) = @_;

    my $attr = $self->associated_attribute;

    return ''
        unless $attr->should_coerce && $attr->type_constraint->has_coercion;

    # We want to break the aliasing in @_ in case the coercion tries to make a
    # destructive change to an array member.
    return '@_ = @{ $attr->type_constraint->coerce($value) };';
}

1;
