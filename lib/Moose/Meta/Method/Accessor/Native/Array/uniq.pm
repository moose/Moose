package Moose::Meta::Method::Accessor::Native::Array::uniq;

use strict;
use warnings;

use List::MoreUtils ();

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Reader';

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "List::MoreUtils::uniq \@{ $slot_access }";
}

1;
