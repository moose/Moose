package Moose::Meta::Method::Accessor::Native::String::replace;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Writer';

sub _minimum_arguments { 1 }
sub _maximum_arguments { 2 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_throw_error(
        q{'The first argument passed to replace must be a string or regexp reference'}
        )
        . q{ unless ! ref $_[0] || ref $_[0] eq 'Regexp';} . "\n"
        . $self->_inline_throw_error(
        q{'The second argument passed to replace must be a string or code reference'}
        ) . q{ unless ! ref $_[1] || ref $_[1] eq 'CODE';};
}

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "( do { my \$val = $slot_access; ref \$_[1] ? \$val =~ s/\$_[0]/\$_[1]->()/e : \$val =~ s/\$_[0]/\$_[1]/; \$val } )";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "if ( ref \$_[1] ) { $slot_access =~ s/\$_[0]/\$_[1]->()/e; } else { $slot_access =~ s/\$_[0]/\$_[1]/; }";
}

1;
