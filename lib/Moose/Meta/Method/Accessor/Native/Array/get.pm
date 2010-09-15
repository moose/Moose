package Moose::Meta::Method::Accessor::Native::Array::get;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Reader';

sub _inline_process_arguments {
    return 'my $idx = shift;';
}

sub _inline_check_arguments {
    return
        q{die 'Must provide a valid index number as an argument' unless defined $idx && $idx =~ /^-?\d+$/;};
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "${slot_access}->[\$idx]";
}

1;
