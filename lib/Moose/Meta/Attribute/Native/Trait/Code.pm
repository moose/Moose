package Moose::Meta::Attribute::Native::Trait::Code;
use Moose::Role;
use Moose::Meta::Attribute::Native::MethodProvider::Code;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

with 'Moose::Meta::Attribute::Native::Trait';

has method_provider => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'Moose::Meta::Attribute::Native::MethodProvider::Code',
);

sub _default_is { 'ro' }
sub _helper_type { 'CodeRef' }

no Moose::Role;

1;

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::Code

=head1 SYNOPSIS

  package Foo;
  use Moose;

  has 'callback' => (
      traits    => ['Code'],
      is        => 'ro',
      isa       => 'CodeRef',
      default   => sub { sub { print "called" } },
      handles   => {
          call => 'execute',
      },
  );

  my $foo = Foo->new;
  $foo->call; # prints "called"


=head1 DESCRIPTION

This provides operations on coderef attributes.

=head1 PROVIDED METHODS

=over 4

=item B<execute(@args)>

Calls the coderef with the given args.

=back

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
