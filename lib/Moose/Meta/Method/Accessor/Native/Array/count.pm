package Moose::Meta::Method::Accessor::Native::Array::count;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Reader';

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "scalar \@{ $slot_access }";
}

1;
