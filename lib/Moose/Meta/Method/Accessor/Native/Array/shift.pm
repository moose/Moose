package Moose::Meta::Method::Accessor::Native::Array::shift;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _maximum_arguments { 0 }

sub _adds_members { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "( \@{ $slot_access } > 1 ? \@{ $slot_access }[ 1 .. \$#{ $slot_access } ] : () )";
}

sub _capture_old_value {
    my ( $self, $slot_access ) = @_;

    if ( $self->associated_attribute->has_trigger ) {
        return 'my $old = $old[-1];';
    }
    else {
        return "my \$old = $slot_access;";
    }
}

sub _return_value {
    my ( $self, $instance, $old_value ) = @_;

    return 'return $old->[0]';
}

1;
