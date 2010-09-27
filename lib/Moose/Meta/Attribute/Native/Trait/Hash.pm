
package Moose::Meta::Attribute::Native::Trait::Hash;
use Moose::Role;

our $VERSION   = '1.15';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Accessor::Native::Hash::accessor;
use Moose::Meta::Method::Accessor::Native::Hash::clear;
use Moose::Meta::Method::Accessor::Native::Hash::count;
use Moose::Meta::Method::Accessor::Native::Hash::defined;
use Moose::Meta::Method::Accessor::Native::Hash::delete;
use Moose::Meta::Method::Accessor::Native::Hash::elements;
use Moose::Meta::Method::Accessor::Native::Hash::exists;
use Moose::Meta::Method::Accessor::Native::Hash::get;
use Moose::Meta::Method::Accessor::Native::Hash::is_empty;
use Moose::Meta::Method::Accessor::Native::Hash::keys;
use Moose::Meta::Method::Accessor::Native::Hash::kv;
use Moose::Meta::Method::Accessor::Native::Hash::set;
use Moose::Meta::Method::Accessor::Native::Hash::values;

with 'Moose::Meta::Attribute::Native::Trait';

sub _helper_type { 'HashRef' }

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::Hash - Helper trait for HashRef attributes

=head1 SYNOPSIS

  package Stuff;
  use Moose;

  has 'options' => (
      traits    => ['Hash'],
      is        => 'ro',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      handles   => {
          set_option     => 'set',
          get_option     => 'get',
          has_no_options => 'is_empty',
          num_options    => 'count',
          delete_option  => 'delete',
          option_pairs   => 'kv',
      },
  );

=head1 DESCRIPTION

This module provides a Hash attribute which provides a number of
hash-like operations.

=head1 PROVIDED METHODS

=over 4

=item B<get($key, $key2, $key3...)>

Returns values from the hash.

In list context return a list of values in the hash for the given keys.
In scalar context returns the value for the last key specified.

=item B<set($key =E<gt> $value, $key2 =E<gt> $value2...)>

Sets the elements in the hash to the given values.

=item B<delete($key, $key2, $key3...)>

Removes the elements with the given keys.

=item B<keys>

Returns the list of keys in the hash.

=item B<exists($key)>

Returns true if the given key is present in the hash.

=item B<defined($key)>

Returns true if the value of a given key is defined.

=item B<values>

Returns the list of values in the hash.

=item B<kv>

Returns the key/value pairs in the hash as an array of array references.

  for my $pair ( $object->options->pairs ) {
      print "$pair->[0] = $pair->[1]\n";
  }

=item B<elements>

Returns the key/value pairs in the hash as a flattened list..

=item B<clear>

Resets the hash to an empty value, like C<%hash = ()>.

=item B<count>

Returns the number of elements in the hash. Also useful for not empty: 
C<< has_options => 'count' >>.

=item B<is_empty>

If the hash is populated, returns false. Otherwise, returns true.

=item B<accessor>

If passed one argument, returns the value of the specified key. If passed two
arguments, sets the value of the specified key.

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
