package Moose::Meta::Method::Accessor::Native::Array::Writer;

use strict;
use warnings;

our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer' => {
        -excludes => ['_inline_coerce_new_values'],
    },
    'Moose::Meta::Method::Accessor::Native::Array',
    'Moose::Meta::Method::Accessor::Native::Collection';

sub _new_members { '@_' }

sub _copy_old_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '[ @{(' . $slot_access . ')} ]';
}

1;
