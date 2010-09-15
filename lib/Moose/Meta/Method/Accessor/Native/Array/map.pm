package Moose::Meta::Method::Accessor::Native::Array::map;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Reader';

sub _inline_process_arguments {
    return 'my $func = shift;';
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "map { \$func->() } \@{ $slot_access }";
}

1;
