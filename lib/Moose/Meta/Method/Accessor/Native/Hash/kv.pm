package Moose::Meta::Method::Accessor::Native::Hash::kv;

use strict;
use warnings;

use Scalar::Util qw( looks_like_number );

our $VERSION = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Reader';

sub _minimum_arguments { 0 }

sub _maximum_arguments { 0 }

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return "map { [ \$_, ${slot_access}->{\$_} ] } keys \%{ $slot_access }";
}


1;
