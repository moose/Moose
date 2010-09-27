package Moose::Meta::Attribute::Native::Trait::String;
use Moose::Role;

our $VERSION   = '1.15';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Accessor::Native::String::append;
use Moose::Meta::Method::Accessor::Native::String::chomp;
use Moose::Meta::Method::Accessor::Native::String::chop;
use Moose::Meta::Method::Accessor::Native::String::clear;
use Moose::Meta::Method::Accessor::Native::String::inc;
use Moose::Meta::Method::Accessor::Native::String::length;
use Moose::Meta::Method::Accessor::Native::String::match;
use Moose::Meta::Method::Accessor::Native::String::prepend;
use Moose::Meta::Method::Accessor::Native::String::replace;
use Moose::Meta::Method::Accessor::Native::String::substr;

with 'Moose::Meta::Attribute::Native::Trait';

sub _default_default { q{} }
sub _default_is { 'rw' }
sub _helper_type { 'Str' }

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::String - Helper trait for Str attributes

=head1 SYNOPSIS

  package MyHomePage;
  use Moose;

  has 'text' => (
      traits    => ['String'],
      is        => 'rw',
      isa       => 'Str',
      default   => q{},
      handles   => {
          add_text     => 'append',
          replace_text => 'replace',
      },
  );

  my $page = MyHomePage->new();
  $page->add_text("foo"); # same as $page->text($page->text . "foo");

=head1 DESCRIPTION

This module provides a simple string attribute, to which mutating string
operations can be applied more easily (no need to make an lvalue attribute
metaclass or use temporary variables). Additional methods are provided for
completion.

If your attribute definition does not include any of I<is>, I<isa>,
I<default> or I<handles> but does use the C<String> metaclass,
then this module applies defaults as in the L</SYNOPSIS>
above. This allows for a very basic string definition:

  has 'foo' => (traits => ['String']);
  $obj->append_foo;

=head1 PROVIDED METHODS

=over 4

=item B<inc>

Increments the value stored in this slot using the magical string autoincrement
operator. Note that Perl doesn't provide analogous behavior in C<-->, so
C<dec> is not available.

=item B<append($string)>

Append a string, like C<.=>.

=item B<prepend($string)>

Prepend a string.

=item B<replace($pattern, $replacement)>

Performs a regexp substitution (L<perlop/s>). There is no way to provide the
C<g> flag, but code references will be accepted for the replacement, causing
the regex to be modified with a single C<e>. C</smxi> can be applied using the
C<qr> operator.

=item B<match($pattern)>

Like C<replace> but without the replacement. Provided mostly for completeness.

=item B<chop>

L<perlfunc/chop>

=item B<chomp>

L<perlfunc/chomp>

=item B<clear>

Sets the string to the empty string (not the value passed to C<default>).

=item B<length>

L<perlfunc/length>

=item B<substr>

L<perlfunc/substr>. We go to some lengths to match the different functionality
based on C<substr>'s arity.

=back

=head1 METHODS

=over 4

=item B<meta>

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
