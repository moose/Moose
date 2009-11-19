package Moose::Error::Default;

use strict;
use warnings;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Carp::Heavy;


sub new {
    my ( $self, @args ) = @_;
    $self->create_error_confess( @args );
}

sub create_error_croak {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args );
}

sub create_error_confess {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args, longmess => 1 );
}

sub _create_error_carpmess {
    my ( $self, %args ) = @_;

    my $carp_level = 3 + ( $args{depth} || 1 );
    local $Carp::MaxArgNums = 20; # default is 8, usually we use named args which gets messier though

    my @args = exists $args{message} ? $args{message} : ();

    if ( $args{longmess} || $Carp::Verbose ) {
        local $Carp::CarpLevel = ( $Carp::CarpLevel || 0 ) + $carp_level;
        return Carp::longmess(@args);
    } else {
        return Carp::ret_summary($carp_level, @args);
    }
}

__PACKAGE__

__END__

=pod

=head1 NAME

Moose::Error::Default - L<Carp> based error generation for Moose.

=head1 DESCRIPTION

This class implements L<Carp> based error generation.

The default behavior is like L<Moose::Error::Confess>.

=head1 METHODS

=over 4

=item new @args

Create a new error. Delegates to C<create_error_confess>.

=item create_error_confess @args

=item create_error_croak @args

Creates a new errors string of the specified style.

=back

=cut


