package Moose::Meta::Method::Accessor::Native::Reader;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native';

requires '_return_value';

sub _generate_method {
    my $self = shift;

    my $inv = '$self';

    my $code = 'sub {';
    $code .= "\n" . $self->_inline_pre_body(@_);

    $code .= "\n" . 'my $self = shift;';

    $code .= "\n" . $self->_inline_curried_arguments;

    my $slot_access = $self->_inline_get($inv);

    $code .= "\n" . $self->_reader_core( $inv, $slot_access, @_ );

    $code .= "\n}";

    return $code;
}

sub _reader_core {
    my ( $self, $inv, $slot_access, @extra ) = @_;

    my $code = q{};

    $code .= "\n" . $self->_inline_check_argument_count;
    $code .= "\n" . $self->_inline_process_arguments( $inv, $slot_access );
    $code .= "\n" . $self->_inline_check_arguments;

    $code .= "\n" . $self->_inline_check_lazy($inv);
    $code .= "\n" . $self->_inline_post_body(@extra);
    $code .= "\n" . $self->_inline_return_value($slot_access);

    return $code;
}

sub _inline_process_arguments {q{}}

sub _inline_check_arguments {q{}}

sub _inline_return_value {
    my ( $self, $slot_access ) = @_;

    'return ' . $self->_return_value($slot_access) . ';';
}

no Moose::Role;

1;
