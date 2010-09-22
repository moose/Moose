package Moose::Meta::Method::Accessor::Native::Counter::Writer;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Writer';

sub _new_value {'$_[0]'}

sub _constraint_must_be_checked {
    my $self = shift;

    my $attr = $self->associated_attribute;

    return $attr->has_type_constraint
        && ( $attr->type_constraint->name =~ /^(?:Num|Int)$/
        || ( $attr->should_coerce && $attr->type_constraint->has_coercion ) );
}

sub _inline_check_coercion {
    my ( $self, $value ) = @_;

    my $attr = $self->associated_attribute;

    return ''
        unless $attr->should_coerce && $attr->type_constraint->has_coercion;

    # We want to break the aliasing in @_ in case the coercion tries to make a
    # destructive change to an array member.
    return "$value = $attr->type_constraint->coerce($value);";
}

1;
