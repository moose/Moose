package Moose::Meta::Method::Accessor::Native::Array::shuffle;

use strict;
use warnings;

use List::Util ();

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader' =>
    { -excludes => ['_maximum_arguments'] };

sub _maximum_arguments { 0 }

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "List::Util::shuffle \@{ ($slot_access) }";
}

no Moose::Role;

1;
