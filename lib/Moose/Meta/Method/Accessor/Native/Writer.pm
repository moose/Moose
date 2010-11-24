package Moose::Meta::Method::Accessor::Native::Writer;

use strict;
use warnings;

use List::MoreUtils qw( any );

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native';

requires '_potential_value';

sub _generate_method {
    my $self = shift;

    my $inv = '$self';

    my $slot_access = $self->_inline_get($inv);

    my $code = 'sub {';

    $code .= "\n" . $self->_inline_pre_body(@_);

    $code .= "\n" . 'my $self = shift;';

    $code .= "\n" . $self->_inline_curried_arguments;

    $code .= $self->_writer_core( $inv, $slot_access );

    $code .= "\n" . $self->_inline_post_body(@_);

    $code .= "\n}";

    return $code;
}

sub _writer_core {
    my ( $self, $inv, $slot_access ) = @_;

    my $code = q{};

    $code .= "\n" . $self->_inline_check_argument_count;
    $code .= "\n" . $self->_inline_process_arguments( $inv, $slot_access );
    $code .= "\n" . $self->_inline_check_arguments('for writer');

    $code .= "\n" . $self->_inline_check_lazy($inv);

    my $potential_value = $self->_potential_value($slot_access);

    if ( $self->_return_value($slot_access) ) {
        # some writers will save the return value in this variable when they
        # generate the potential value.
        $code .= "\n" . 'my @return;';
    }

    # This is only needed by collections.
    $code .= "\n" . $self->_inline_coerce_new_values;
    $code .= "\n" . $self->_inline_copy_native_value( \$potential_value );
    $code .= "\n"
        . $self->_inline_tc_code(
        $potential_value
        );

    $code .= "\n" . $self->_inline_get_old_value_for_trigger($inv);
    $code .= "\n" . $self->_inline_capture_return_value($slot_access);
    $code .= "\n"
        . $self->_inline_set_new_value(
        $inv,
        $potential_value,
        $slot_access,
        ) . ';';
    $code .= "\n" . $self->_inline_trigger( $inv, $slot_access, '@old' );
    $code .= "\n" . $self->_return_value( $slot_access, 'for writer' );

    return $code;
}

sub _inline_process_arguments {q{}}

sub _inline_check_arguments {q{}}

sub _inline_coerce_new_values {q{}}

sub _value_needs_copy {
    my $self = shift;

    return $self->_constraint_must_be_checked;
}

sub _constraint_must_be_checked {
    my $self = shift;

    my $attr = $self->associated_attribute;

    return $attr->has_type_constraint
        && ( !$self->_is_root_type( $attr->type_constraint )
        || ( $attr->should_coerce && $attr->type_constraint->has_coercion ) );
}

sub _is_root_type {
    my ($self, $type) = @_;

    my $name = $type->name();

    return any { $name eq $_ } @{ $self->root_types };
}

sub _inline_copy_native_value {
    my ( $self, $potential_ref ) = @_;

    return q{} unless $self->_value_needs_copy;

    my $code = "my \$potential = ${$potential_ref};";

    ${$potential_ref} = '$potential';

    return $code;
}

sub _inline_tc_code {
    my ( $self, $potential_value ) = @_;

    return q{} unless $self->_constraint_must_be_checked;

    return $self->_inline_check_coercion($potential_value) . "\n"
        . $self->_inline_check_constraint($potential_value);
}

sub _inline_check_coercion {
    my ( $self, $value ) = @_;

    my $attr = $self->associated_attribute;

    return q{}
        unless $attr->should_coerce
            && $attr->type_constraint->has_coercion;

    # We want to break the aliasing in @_ in case the coercion tries to make a
    # destructive change to an array member.
    return "$value = \$type_constraint_obj->coerce($value);";
}

override _inline_check_constraint => sub {
    my ( $self, $value, $for_lazy ) = @_;

    return q{} unless $for_lazy || $self->_constraint_must_be_checked;

    return super();
};

sub _inline_capture_return_value { return q{} }

sub _inline_set_new_value {
    my $self = shift;

    return $self->_inline_store(@_)
        if $self->_value_needs_copy
        || !$self->_slot_access_can_be_inlined
        || !$self->_inline_get_is_lvalue;

    return $self->_inline_optimized_set_new_value(@_);
}

sub _inline_get_is_lvalue {
    my $self = shift;

    return $self->associated_attribute->associated_class->instance_metaclass->inline_get_is_lvalue;
}

sub _inline_optimized_set_new_value {
    my $self = shift;

    return $self->_inline_store(@_);
}

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return $slot_access;
}

no Moose::Role;

1;
