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

    $code .= "\n" . $self->_inline_check_lazy($inv);

    $code .= "\n" . $self->_inline_curried_arguments;

    $code .= "\n" . $self->_inline_check_argument_count;

    $code .= "\n" . $self->_inline_process_arguments;

    $code .= "\n" . $self->_inline_check_arguments;

    my $new_value       = $self->_new_value($slot_access);
    my $potential_value = $self->_potential_value($slot_access);

    $code .= "\n" . $self->_inline_copy_value( \$potential_value );

    $code .= "\n"
        . $self->_inline_tc_code(
        $new_value,
        $potential_value
        );

    $code .= "\n" . $self->_inline_get_old_value_for_trigger($inv);
    $code .= "\n" . $self->_capture_old_value($slot_access);

    $code .= "\n"
        . $self->_inline_set_new_value(
        $inv,
        $potential_value
        );

    $code .= "\n" . $self->_inline_post_body(@_);
    $code .= "\n" . $self->_inline_trigger( $inv, $slot_access, '@old' );

    $code .= "\n" . $self->_return_value( $inv, '@old' );

    $code .= "\n}";

    return $code;
}

sub _inline_process_arguments {q{}}

sub _inline_check_arguments {q{}}

sub _value_needs_copy {0}

sub _inline_tc_code {die}

sub _inline_check_coercion {die}

sub _inline_check_constraint {
    my $self = shift;

    return q{} unless $self->_constraint_must_be_checked;

    return $self->SUPER::_inline_check_constraint( $_[0] );
}

sub _constraint_must_be_checked {die}

sub _capture_old_value { return q{} }

sub _inline_set_new_value {
    my $self = shift;

    return $self->SUPER::_inline_store(@_);
}

sub _return_value      { return q{} }

1;
