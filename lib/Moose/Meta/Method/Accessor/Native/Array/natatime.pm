package Moose::Meta::Method::Accessor::Native::Array::natatime;

use strict;
use warnings;

use List::MoreUtils ();
use Params::Util ();

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader' => {
    -excludes => [
        qw(
            _minimum_arguments
            _maximum_arguments
            _inline_check_arguments
            _inline_return_value
            )
    ]
};

sub _minimum_arguments {1}

sub _maximum_arguments {2}

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_throw_error(
        q{'The n value passed to natatime must be an integer'})
        . ' unless defined $_[0] && $_[0] =~ /^\\d+$/;' . "\n"
        . $self->_inline_throw_error(
        q{'The second argument passed to natatime must be a code reference'})
        . q{ if @_ == 2 && ! Params::Util::_CODELIKE( $_[1] );};
}

sub _inline_return_value {
    my ( $self, $slot_access ) = @_;

    return
        "my \$iter = List::MoreUtils::natatime( \$_[0], \@{ ($slot_access) } );"
        . "\n"
        . 'if ( $_[1] ) {' . "\n"
        . 'while (my @vals = $iter->()) {' . "\n"
        . '$_[1]->(@vals);' . "\n" . '}' . "\n"
        . '} else {' . "\n"
        . 'return $iter;' . "\n" . '}';
}

# Not called, but needed to satisfy the Reader role
sub _return_value { }

no Moose::Role;

1;
