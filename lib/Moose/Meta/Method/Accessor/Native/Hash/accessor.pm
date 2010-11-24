package Moose::Meta::Method::Accessor::Native::Hash::accessor;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Hash::set' => {
    -excludes => [
        qw(
            _generate_method
            _minimum_arguments
            _maximum_arguments
            _inline_check_arguments
            _return_value
            )
    ]
    },
    'Moose::Meta::Method::Accessor::Native::Hash::get' => {
    -excludes => [
        qw(
            _generate_method
            _minimum_arguments
            _maximum_arguments
            _inline_check_argument_count
            _inline_process_arguments
            )
    ]
    };

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

    $code .= "\n" . $self->_inline_check_var_is_valid_key('$_[0]');

    $code
        .= "\n"
        . 'return '
        . $self
        ->Moose::Meta::Method::Accessor::Native::Hash::get::_return_value(
        $slot_access)
        . ';';

    # set
    $code .= "\n" . '} else {';

    $code .= "\n" . $self->_writer_core( $inv, $slot_access );

    $code .= "\n" . $self->_inline_post_body(@_);

    $code .= "\n}";
    $code .= "\n}";

    return $code;
}

sub _minimum_arguments {1}
sub _maximum_arguments {2}

no Moose::Role;

1;
