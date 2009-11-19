package Moose::Error::Confess;

use strict;
use warnings;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base qw(Moose::Error::Default);

__PACKAGE__

__END__

=pod

=head1 NAME

Moose::Error::Confess - Prefer C<confess>

=head1 SYNOPSIS

    # Metaclass definition must come before Moose is used.
    use metaclass (
        metaclass => 'Moose::Meta::Class',
        error_class => 'Moose::Error::Confess',
    );
    use Moose;
    # ...

=head1 DESCRIPTION

This error class uses L<Carp/confess> to raise errors generated in your
metaclass.

=cut



