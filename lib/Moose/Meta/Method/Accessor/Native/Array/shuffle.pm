package Moose::Meta::Method::Accessor::Native::Array::shuffle;

use strict;
use warnings;

use List::Util ();

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Reader';

sub _maximum_arguments { 0 }

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "List::Util::shuffle \@{ $slot_access }";
}

1;
