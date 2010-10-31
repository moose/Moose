package Moose::Meta::Method::Accessor::Native::String::chomp;

use strict;
use warnings;

our $VERSION = '1.19';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer' => {
    -excludes => [
        qw(
            _maximum_arguments
            _optimized_set_new_value
            _return_value
            )
    ]
};

sub _maximum_arguments {0}

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '(do { '
             . 'my $val = ' . $slot_access . '; '
             . '@return = chomp $val; '
             . '$val '
         . '})';
}

sub _optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return '@return = chomp ' . $slot_access;
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '$return[0]';
}

no Moose::Role;

1;
