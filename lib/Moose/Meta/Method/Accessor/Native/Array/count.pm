package Moose::Meta::Method::Accessor::Native::Array::count;

use strict;
use warnings;

our $VERSION = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Reader';

sub _maximum_arguments { 0 }

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return "scalar \@{ $slot_access }";
}

1;
