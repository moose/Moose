package Moose::Meta::Method::Accessor::Native::Code::execute_method;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Reader';

sub _minimum_arguments { 0 }
sub _maximum_arguments { undef }

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return "${slot_access}->(\$self, \@_)";
}

1;
