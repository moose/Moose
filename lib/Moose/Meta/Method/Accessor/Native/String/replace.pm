package Moose::Meta::Method::Accessor::Native::String::replace;

use strict;
use warnings;

use Moose::Util ();
use Params::Util ();

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer' => {
    -excludes => [
        qw(
            _minimum_arguments
            _maximum_arguments
            _inline_check_arguments
            _inline_optimized_set_new_value
            )
    ]
    };

sub _minimum_arguments { 1 }

sub _maximum_arguments { 2 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_throw_error(
        q{'The first argument passed to replace must be a string or regexp reference'}
        )
        . q{ unless Moose::Util::_STRINGLIKE0( $_[0] ) || Params::Util::_REGEX( $_[0] );}
        . $self->_inline_throw_error(
        q{'The second argument passed to replace must be a string or code reference'}
        ) . q{ unless Moose::Util::_STRINGLIKE0( $_[1] ) || Params::Util::_CODELIKE( $_[1] );};
}

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "( do { my \$val = $slot_access; ref \$_[1] ? \$val =~ s/\$_[0]/\$_[1]->()/e : \$val =~ s/\$_[0]/\$_[1]/; \$val } )";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "if ( ref \$_[1] ) { $slot_access =~ s/\$_[0]/\$_[1]->()/e; } else { $slot_access =~ s/\$_[0]/\$_[1]/; }";
}

no Moose::Role;

1;
