package Moose::Meta::Method::Accessor::Native::Array::accessor;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base qw(
    Moose::Meta::Method::Accessor::Native::Array::get
    Moose::Meta::Method::Accessor::Native::Array::set
);

sub _generate_method {
    my $self = shift;

    my $inv = '$self';

    my $code = 'sub {';
    $code .= "\n" . $self->_inline_pre_body(@_);

    $code .= "\n" . 'my $self = shift;';

    $code .= "\n" . $self->_inline_curried_arguments;

    $code .= "\n" . $self->_inline_check_lazy($inv);

    my $slot_access = $self->_inline_get($inv);

    # get
    $code .= "\n" . 'if ( @_ == 1 ) {';

    $code .= "\n" . $self->_inline_check_var_is_valid_index('$_[0]');

    $code .= "\n" . 'return ' . $self->_return_value($slot_access) . ';';

    # set
    $code .= "\n" . '} else {';

    $code .= "\n" . $self->_inline_check_argument_count;
    $code
        .= "\n"
        . $self
        ->Moose::Meta::Method::Accessor::Native::Array::set::_inline_check_arguments;

    my $new_values      = $self->_new_values($slot_access);
    my $potential_value = $self->_potential_value($slot_access);

    $code .= "\n"
        . $self->_inline_tc_code(
        $new_values,
        $potential_value
        );

    $code .= "\n" . $self->_inline_get_old_value_for_trigger($inv);
    $code .= "\n" . $self->_capture_old_value($slot_access);

    $code
        .= "\n" . $self->_inline_store( $inv, '[' . $potential_value . ']' );

    $code .= "\n" . $self->_inline_post_body(@_);
    $code .= "\n" . $self->_inline_trigger( $inv, $slot_access, '@old' );

    $code .= "\n}";
    $code .= "\n}";

    return $code;
}

# If we get one argument we won't check the argument count
sub _minimum_arguments {2}
sub _maximum_arguments {2}

sub _adds_members {1}

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return
        "( do { my \@potential = \@{ $slot_access }; \$potential[ \$_[0] ] = \$_[1]; \@potential } )";
}

sub _new_values {'$_[1]'}

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
