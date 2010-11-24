package Moose::Meta::Method::Accessor::Native::Code::execute_method;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return "${slot_access}->(\$self, \@_)";
}

no Moose::Role;

1;
