
package Moose::Meta::Attribute::Native::Trait::Counter;
use Moose::Role;

our $VERSION   = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Attribute::Native::MethodProvider::Counter;

with 'Moose::Meta::Attribute::Native::Trait';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'Moose::Meta::Attribute::Native::MethodProvider::Counter',
);

sub _default_default { 0 }
sub _default_is { 'ro' }
sub _helper_type { 'Num' }

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::Counter - Helper trait for counters

=head1 SYNOPSIS

  package MyHomePage;
  use Moose;

  has 'counter' => (
      traits    => ['Counter'],
      is        => 'ro',
      isa       => 'Num',
      default   => 0,
      handles   => {
          inc_counter   => 'inc',
          dec_counter   => 'dec',
          reset_counter => 'reset',
      },
  );

  my $page = MyHomePage->new();
  $page->inc_counter; # same as $page->counter( $page->counter + 1 );
  $page->dec_counter; # same as $page->counter( $page->counter - 1 );
  
  my $count_by_twos = 2;
  $page->inc_counter($count_by_twos);

=head1 DESCRIPTION

This module provides a simple counter attribute, which can be
incremented and decremented by arbitrary amounts.  The default
amount of change is one.

=head1 PROVIDED METHODS

These methods are implemented in
L<Moose::Meta::Attribute::Native::MethodProvider::Counter>. It is important to
note that all those methods do in place modification of the value stored in
the attribute.

=over 4

=item B<set($value)>

Set the counter to the specified value.

=item B<inc($arg)>

Increase the attribute value by the amount of the argument.  
No argument increments the value by 1. 

=item B<dec($arg)>

Decrease the attribute value by the amount of the argument.  
No argument decrements the value by 1.

=item B<reset>

Resets the value stored in this slot to it's default value.

=back

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
