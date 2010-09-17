package Moose::Meta::Method::Accessor::Native::Array::Writer;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array';

sub _generate_method {
    my $self = shift;

    my $inv = '$self';

    my $slot_access = $self->_inline_get($inv);

    my $code = 'sub {';
    $code .= "\n" . $self->_inline_pre_body(@_);

    $code .= "\n" . 'my $self = shift;';

    $code .= "\n" . $self->_inline_check_lazy($inv);

    $code .= "\n" . $self->_inline_curried_arguments;

    $code .= "\n" . $self->_inline_check_argument_count;

    $code .= "\n" . $self->_inline_process_arguments;

    $code .= "\n" . $self->_inline_check_arguments;

    my $new_values      = $self->_new_values($slot_access);
    my $potential_value = $self->_potential_value($slot_access);

    $code .= "\n"
        . $self->_inline_tc_code(
        $new_values,
        $potential_value
        );

    $code .= "\n" . $self->_inline_get_old_value_for_trigger($inv);
    $code .= "\n" . $self->_capture_old_value($slot_access);

    $code .= "\n" . $self->_inline_store( $inv, '[' . $potential_value . ']' );

    $code .= "\n" . $self->_inline_post_body(@_);
    $code .= "\n" . $self->_inline_trigger( $inv, $slot_access, '@old' );

    $code .= "\n" . $self->_return_value( $inv, '@old' );

    $code .= "\n}";

    return $code;
}

sub _inline_process_arguments { q{} }

sub _inline_check_arguments { q{} }

sub _new_values { '@_' }

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
    # ArrayRef.
    return 1 if $tc->parent->name eq 'ArrayRef';

    # If our parent is something else ( subtype 'Foo' as 'ArrayRef[Str]' )
    # then there may be additional constraints on the whole value, as opposed
    # to constraints just on the members.
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

    # We want to break the aliasing in @_ in case the coercion tries to make a
    # destructive change to an array member.
    my $code = 'my @copy = @{ $value }';
    return '@_ = @{ $attr->type_constraint->coerce(\@copy) };';
}

sub _inline_check_constraint {
    my $self = shift;

    return q{} unless $self->_constraint_must_be_checked;

    return $self->SUPER::_inline_check_constraint(@_);
}

sub _capture_old_value { return q{} }
sub _return_value { return q{} }

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
