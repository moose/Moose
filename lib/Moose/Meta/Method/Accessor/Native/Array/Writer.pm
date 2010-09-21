package Moose::Meta::Method::Accessor::Native::Array::Writer;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base qw(
    Moose::Meta::Method::Accessor::Native::Array
    Moose::Meta::Method::Accessor::Native::Writer
);

sub _inline_process_arguments {q{}}

sub _inline_check_arguments {q{}}

sub _new_value {'@_'}

sub _inline_copy_value {
    my ( $self, $potential_ref ) = @_;

    return q{} unless $self->_value_needs_copy;

    my $code = "my \$potential = ${$potential_ref};";

    ${$potential_ref} = '$potential';

    return $code;
}

sub _value_needs_copy {
    my $self = shift;

    return $self->_constraint_must_be_checked
        && !$self->_check_new_members_only;
}

sub _inline_tc_code {
    my ( $self, $new_value, $potential_value ) = @_;

    return q{} unless $self->_constraint_must_be_checked;

    if ( $self->_check_new_members_only ) {
        return q{} unless $self->_adds_members;

        return $self->_inline_check_member_constraint($new_value);
    }
    else {
        return $self->_inline_check_coercion($potential_value) . "\n"
            . $self->_inline_check_constraint($potential_value);
    }
}

sub _constraint_must_be_checked {
    my $self = shift;

    my $attr = $self->associated_attribute;

    return $attr->has_type_constraint
        && ( $attr->type_constraint->name ne 'ArrayRef'
        || ( $attr->should_coerce && $attr->type_constraint->has_coercion ) );
}

sub _check_new_members_only {
    my $self = shift;

    my $attr = $self->associated_attribute;

    my $tc = $attr->type_constraint;

    # If we have a coercion, we could come up with an entirely new value after
    # coercing, so we need to check everything,
    return 0 if $attr->should_coerce && $tc->has_coercion;

    # If the parent is ArrayRef, that means we can just check the new members
    # of the collection, because we know that we will always be generating an
    # ArrayRef. However, if this type has its own constraint, we don't know
    # what the constraint checks, so we need to check the whole value, not
    # just the members.
    return 1
        if $tc->parent->name eq 'ArrayRef'
            && $tc->isa('Moose::Meta::TypeConstraint::Parameterized');

    return 0;
}

sub _inline_check_member_constraint {
    my ( $self, $new_value ) = @_;

    my $attr_name = $self->associated_attribute->name;

    return '$member_tc->($_) || '
        . $self->_inline_throw_error(
        qq{"A new member value for '$attr_name' does not pass its type constraint because: "}
            . ' . $member_tc->get_message($_)',
        "data => \$_"
        ) . " for $new_value;";
}

sub _inline_check_coercion {
    my ( $self, $value ) = @_;

    my $attr = $self->associated_attribute;

    return ''
        unless $attr->should_coerce && $attr->type_constraint->has_coercion;

    return "$value = \$type_constraint_obj->coerce($value);";
}

sub _inline_check_constraint {
    my $self = shift;

    return q{} unless $self->_constraint_must_be_checked;

    return $self->SUPER::_inline_check_constraint( $_[0] );
}

sub _inline_get_old_value_for_trigger {
    my ( $self, $instance ) = @_;

    my $attr = $self->associated_attribute;
    return '' unless $attr->has_trigger;

    my $mi = $attr->associated_class->get_meta_instance;
    my $pred = $mi->inline_is_slot_initialized( $instance, $attr->name );

    return
          'my @old = '
        . $pred . q{ ? } . '[ @{'
        . $self->_inline_get($instance)
        . '} ] : ()' . ";\n";
}

sub _return_value      { return q{} }

sub _eval_environment {
    my $self = shift;

    my $env = $self->SUPER::_eval_environment;

    return $env
        unless $self->_constraint_must_be_checked
            and $self->_check_new_members_only;

    $env->{'$member_tc'}
        = \( $self->associated_attribute->type_constraint->type_parameter
            ->_compiled_type_constraint );

    return $env;
}

1;
