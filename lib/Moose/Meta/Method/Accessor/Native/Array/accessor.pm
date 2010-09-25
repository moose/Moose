package Moose::Meta::Method::Accessor::Native::Array::accessor;

use strict;
use warnings;

our $VERSION = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base qw(
    Moose::Meta::Method::Accessor::Native::Array::set
    Moose::Meta::Method::Accessor::Native::Array::get
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

    $code
        .= "\n"
        . 'return '
        . $self
        ->Moose::Meta::Method::Accessor::Native::Array::get::_return_value(
        $slot_access)
        . ';';

    # set
    $code .= "\n" . '} else {';

    $code .= "\n" . $self->_inline_check_argument_count;
    $code .= "\n" . $self->_inline_process_arguments( $inv, $slot_access );
    $code
        .= "\n"
        . $self
        ->Moose::Meta::Method::Accessor::Native::Array::set::_inline_check_arguments;

    my $potential_value = $self->_potential_value($slot_access);

    $code .= "\n" . $self->_inline_copy_value( \$potential_value );
    $code .= "\n"
        . $self->_inline_tc_code(
        $potential_value,
        $slot_access,
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
    $code .= "\n" . $self->_inline_post_body(@_);

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

sub _new_members {'$_[1]'}

1;
