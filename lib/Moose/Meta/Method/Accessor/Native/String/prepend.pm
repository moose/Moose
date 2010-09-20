package Moose::Meta::Method::Accessor::Native::String::prepend;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::String::Writer';

sub _minimum_arguments { 1 }
sub _maximum_arguments { 1 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "( \$_[0] . $slot_access )";
}

1;
