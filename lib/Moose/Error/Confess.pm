package Moose::Error::Confess;

use strict;
use warnings;

use base qw(Moose::Error::Default);

__PACKAGE__

__END__

=pod

=head1 NAME

Moose::Error::Confess - Prefer C<confess>

=head1 SYNOPSIS

	use metaclass => (
        metaclass => "Moose::Meta::Class",
        error_class => "Moose::Error::Confess",
    );

=head1 DESCRIPTION

This error class uses L<Carp/confess> to raise errors generated in your
metaclass.

=cut



