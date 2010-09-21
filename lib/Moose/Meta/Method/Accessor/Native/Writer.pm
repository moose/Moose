package Moose::Meta::Method::Accessor::Native::Writer;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native';

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

    my $new_value       = $self->_new_value($slot_access);
    my $potential_value = $self->_potential_value($slot_access);

    $code .= "\n" . $self->_inline_copy_value( \$potential_value );
    $code .= "\n"
        . $self->_inline_tc_code(
        $new_value,
        $potential_value
        );

    $code .= "\n" . $self->_inline_get_old_value_for_trigger($inv);
    $code .= "\n" . $self->_inline_capture_return_value($slot_access);
    $code .= "\n"
        . $self->_inline_set_new_value(
        $inv,
        $potential_value,
        $slot_access,
        );
    $code .= "\n" . $self->_inline_trigger( $inv, $slot_access, '@old' );
    $code .= "\n" . $self->_return_value( $slot_access, 'for writer' );

    return $code;
}

sub _inline_process_arguments {q{}}

sub _inline_check_arguments {q{}}

sub _value_needs_copy {
    my $self = shift;

    return $self->_constraint_must_be_checked;
}

sub _inline_copy_value {
    my ( $self, $potential_ref ) = @_;

    return q{} unless $self->_value_needs_copy;

    my $code = "my \$potential = ${$potential_ref};";

    ${$potential_ref} = '$potential';

    return $code;
}

sub _inline_tc_code {
    die '_inline_tc_code must be overridden by ' . ref $_[0];
}

sub _inline_check_coercion {
    die '_inline_check_coercion must be overridden by ' . ref $_[0];
}

sub _inline_check_constraint {
    my $self = shift;

    return q{} unless $self->_constraint_must_be_checked;

    return $self->SUPER::_inline_check_constraint( $_[0] );
}

sub _constraint_must_be_checked {
    die '_constraint_must_be_checked must be overridden by ' . ref $_[0];
}

sub _inline_capture_return_value { return q{} }

sub _inline_set_new_value {
    my $self = shift;

    return $self->SUPER::_inline_store(@_)
        if $self->_value_needs_copy;

    return $self->_inline_optimized_set_new_value(@_);
}

sub _inline_optimized_set_new_value {
    my $self = shift;

    return $self->SUPER::_inline_store(@_)
}

sub _return_value { return q{} }

1;
