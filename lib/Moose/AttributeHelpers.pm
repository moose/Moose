
package Moose::AttributeHelpers;

our $VERSION   = '0.83';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose 0.56 ();

use Moose::AttributeHelpers::Trait::Bool;
use Moose::AttributeHelpers::Trait::Counter;
use Moose::AttributeHelpers::Trait::Number;
use Moose::AttributeHelpers::Trait::String;
use Moose::AttributeHelpers::Trait::Collection::List;
use Moose::AttributeHelpers::Trait::Collection::Array;
use Moose::AttributeHelpers::Trait::Collection::Hash;
use Moose::AttributeHelpers::Trait::Collection::ImmutableHash;
use Moose::AttributeHelpers::Trait::Collection::Bag;

use Moose::AttributeHelpers::Counter;
use Moose::AttributeHelpers::Number;
use Moose::AttributeHelpers::String;
use Moose::AttributeHelpers::Bool;
use Moose::AttributeHelpers::Collection::List;
use Moose::AttributeHelpers::Collection::Array;
use Moose::AttributeHelpers::Collection::Hash;
use Moose::AttributeHelpers::Collection::ImmutableHash;
use Moose::AttributeHelpers::Collection::Bag;

1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers - Extend your attribute interfaces

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  use Moose::AttributeHelpers;

  has 'mapping' => (
      metaclass => 'Collection::Hash',
      is        => 'rw',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      handles   => {
          exists_in_mapping => 'exists',
          ids_in_mapping    => 'keys',
          get_mapping       => 'get',
          set_mapping       => 'set',
          set_quantity      => [ set => [ 'quantity' ] ],
      },
  );


  # ...

  my $obj = MyClass->new;
  $obj->set_quantity(10);      # quantity => 10
  $obj->set_mapping(4, 'foo'); # 4 => 'foo'
  $obj->set_mapping(5, 'bar'); # 5 => 'bar'
  $obj->set_mapping(6, 'baz'); # 6 => 'baz'


  # prints 'bar'
  print $obj->get_mapping(5) if $obj->exists_in_mapping(5);

  # prints '4, 5, 6'
  print join ', ', $obj->ids_in_mapping;

=head1 DESCRIPTION

While L<Moose> attributes provide you with a way to name your accessors,
readers, writers, clearers and predicates, this library provides commonly
used attribute helper methods for more specific types of data.

As seen in the L</SYNOPSIS>, you specify the extension via the
C<trait> parameter. Available meta classes are below; see L</METHOD PROVIDERS>.

=head1 PARAMETERS

=head2 handles

This is like C<< handles >> in L<Moose/has>, but only HASH references are
allowed.  Keys are method names that you want installed locally, and values are
methods from the method providers (below).  Currying with delegated methods works normally for C<< handles >>.

=head1 METHOD PROVIDERS

=over

=item L<Number|Moose::AttributeHelpers::Trait::Number>

Common numerical operations.

=item L<String|Moose::AttributeHelpers::Trait::String>

Common methods for string operations.

=item L<Counter|Moose::AttributeHelpers::Trait::Counter>

Methods for incrementing and decrementing a counter attribute.

=item L<Bool|Moose::AttributeHelpers::Trait::Bool>

Common methods for boolean values.

=item L<Collection::Hash|Moose::AttributeHelpers::Trait::Collection::Hash>

Common methods for hash references.

=item L<Collection::ImmutableHash|Moose::AttributeHelpers::Trait::Collection::ImmutableHash>

Common methods for inspecting hash references.

=item L<Collection::Array|Moose::AttributeHelpers::Trait::Collection::Array>

Common methods for array references.

=item L<Collection::List|Moose::AttributeHelpers::Trait::Collection::List>

Common list methods for array references.

=back

=head1 CAVEAT

This is an early release of this module. Right now it is in great need
of documentation and tests in the test suite. However, we have used this
module to great success at C<$work> where it has been tested very thoroughly
and deployed into a major production site.

I plan on getting better docs and tests in the next few releases, but until
then please refer to the few tests we do have and feel free email and/or
message me on irc.perl.org if you have any questions.

=head1 TODO

We need tests and docs badly.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

B<with contributions from:>

Robert (rlb3) Boone

Paul (frodwith) Driver

Shawn (Sartak) Moore

Chris (perigrin) Prather

Robert (phaylon) Sedlacek

Tom (dec) Lanyon

Yuval Kogman

Jason May

Cory (gphat) Watson

Florian (rafl) Ragwitz

Evan Carroll

Jesse (doy) Luehrs

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
