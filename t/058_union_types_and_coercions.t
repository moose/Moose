#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

__END__

package Email::Moose;

use warnings;
use strict;

use Moose;
use Moose::Util::TypeConstraints;

use IO::String;

=head1 NAME

Email::Moose - Email::Simple on Moose steroids

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=head1 METHODS

=head2 raw_body

=cut

subtype q{IO::String}
  => as q{Object}
  => where { $_->isa(q{IO::String}) };

coerce q{IO::String}
  => from q{Str}
    => via { IO::String->new($_) },
  => from q{ScalarRef},
    => via { IO::String->new($_) };

type q{FileHandle}
  => where { Scalar::Util::openhandle($_) };
  
subtype q{IO::File}
  => as q{Object}
  => where { $_->isa(q{IO::File}) };

coerce q{IO::File}
  => from q{FileHandle}
    => via { bless $_, q{IO::File} };

subtype q{IO::Socket}
  => as q{Object}
  => where { $_->isa(q{IO::Socket}) };

coerce q{IO::Socket}
  => from q{CodeRef} # no test sample yet
    => via { IO::Socket->new($_) };
=cut
    
has q{raw_body} => (
  is      => q{rw},
  isa     => q{IO::String | IO::File | IO::Socket},
  coerce  => 1,
  default => sub { IO::String->new() },
);

=head2 as_string

=cut

sub as_string {
  my ($self) = @_;
  my $fh = $self->raw_body();
  return do { local $/; <$fh> };
}