package Moose::Meta::Attribute::Native::Trait::Code;
use Moose::Role;

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Accessor::Native::Code::execute;
use Moose::Meta::Method::Accessor::Native::Code::execute_method;

with 'Moose::Meta::Attribute::Native::Trait';

sub _helper_type { 'CodeRef' }

no Moose::Role;

1;

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::Code - Helper trait for Code attributes

=head1 SYNOPSIS

  package Foo;
  use Moose;

  has 'callback' => (
      traits  => ['Code'],
      is      => 'ro',
      isa     => 'CodeRef',
      default => sub {
          sub { print "called" }
      },
      handles => {
          call => 'execute',
      },
  );

  my $foo = Foo->new;
  $foo->call;    # prints "called"

=head1 DESCRIPTION

This trait provides native delegation methods for code references.

=head1 DEFAULT TYPE

If you don't provide an C<isa> value for your attribute, it will default to
C<CodeRef>.

=head1 PROVIDED METHODS

=over 4

=item * B<execute(@args)>

Calls the coderef with the given args.

=item * B<execute_method(@args)>

Calls the coderef with the the instance as invocant and given args.

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
