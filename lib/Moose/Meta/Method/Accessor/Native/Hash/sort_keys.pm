package Moose::Meta::Method::Accessor::Native::Hash::sort_keys;

# return the sorted list of keys to the hash, a la:
#
#   sort keys %$hash

use Moose::Role 1.15;

with
    'Moose::Meta::Method::Accessor::Native::Array::sort' => {
        -excludes => [qw{ _return_value }],
        -alias    => { _return_value => '_array_return_value' },
    },
    'Moose::Meta::Method::Accessor::Native::Hash',
    ;

sub _return_value {
    my ($self, $slot_access) = @_;

    return $self->_array_return_value("[ keys %{ $slot_access } ]");
}

no Moose::Role;
1;
