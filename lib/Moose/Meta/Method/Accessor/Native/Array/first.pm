package Moose::Meta::Method::Accessor::Native::Array::first;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Reader';

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "${slot_access}->[0]";
}

1;
