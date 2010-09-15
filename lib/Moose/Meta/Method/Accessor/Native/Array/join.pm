package Moose::Meta::Method::Accessor::Native::Array::join;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Reader';

sub _inline_process_arguments {
    return 'my $sep = shift;';
}

sub _inline_check_arguments {
    return
        q{die 'Must provide a string as an argument' unless defined $sep && ! ref $sep;};
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "join \$sep, \@{ $slot_access }";
}

1;
