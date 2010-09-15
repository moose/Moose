package Moose::Meta::Method::Accessor::Native::Array::push;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _generate_method {
    my $self = shift;

    my $inv = '$self';

    my $slot_access = $self->_inline_get($inv);

    my $code = 'sub {';
    $code .= "\n" . $self->_inline_pre_body(@_);

    $code .= "\n" . 'my $self = shift;';

    $code .= "\n" . $self->_inline_check_lazy($inv);

    $code .= "\n" . $self->_inline_curried_arguments;

    $code
        .= "\n"
        . $self->_inline_throw_error(
        q{"Cannot call push without any arguments"})
        . " unless \@_;";

    my $potential_new_val;
    if ( $self->_constraint_must_be_checked ) {
        $code .= "\n" . "my \@new_val = ( \@{ $slot_access }, \@_ );";
        $potential_new_val = '\\@new_val';
    }
    else {
        $potential_new_val = "[ \@{ $slot_access }, \@_ ];";
    }

    $code .= "\n" . $self->_inline_check_coercion($potential_new_val);
    $code .= "\n" . $self->_inline_check_constraint($potential_new_val);

    $code .= "\n" . $self->_inline_get_old_value_for_trigger( $inv, '@_' );

    $code .= "\n" . $self->_inline_store( $inv, $potential_new_val );

    $code .= "\n" . $self->_inline_post_body(@_);
    $code .= "\n" . $self->_inline_trigger( $inv, '@_', '@old' );

    $code .= "\n}";

    return $code;
}

1;
