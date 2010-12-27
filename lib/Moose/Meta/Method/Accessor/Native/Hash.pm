package Moose::Meta::Method::Accessor::Native::Hash;

use strict;
use warnings;

use Moose::Role;

sub _inline_check_var_is_valid_key {
    my $self = shift;
    my ($var) = @_;

    return (
        'if (!defined(' . $var . ')) {',
            $self->_inline_throw_error(
                '"The key passed to ' . $self->delegate_to_method
              . ' must be a defined value"',
            ) . ';',
        '}',
    );
}

no Moose::Role;

1;
