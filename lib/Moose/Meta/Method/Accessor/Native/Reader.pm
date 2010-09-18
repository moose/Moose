package Moose::Meta::Method::Accessor::Native::Reader;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native';

sub _generate_method {
    my $self = shift;

    my $inv = '$self';

    my $code = 'sub {';
    $code .= "\n" . $self->_inline_pre_body(@_);

    $code .= "\n" . 'my $self = shift;';
    $code .= "\n" . $self->_inline_curried_arguments;
    $code .= "\n" . $self->_inline_check_argument_count;
    $code .= "\n" . $self->_inline_check_arguments;

    $code .= "\n" . $self->_inline_check_lazy($inv);
    $code .= "\n" . $self->_inline_post_body(@_);

    my $slot_access = $self->_inline_get($inv);

    $code .= "\n" . $self->_inline_return_value($slot_access);
    $code .= "\n}";

    return $code;
}

sub _inline_return_value {
    my ( $self, $slot_access ) = @_;

    'return ' . $self->_return_value($slot_access) . ';';
}

1;
