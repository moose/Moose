
package Moose::Meta::Attribute::Native::Trait::Array;
use Moose::Role;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Attribute::Native::MethodProvider::Array;

with 'Moose::Meta::Attribute::Native::Trait';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'Moose::Meta::Attribute::Native::MethodProvider::Array'
);

sub _helper_type { 'ArrayRef' }

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::Array - Helper trait for ArrayRef attributes

=head1 SYNOPSIS

    package Stuff;
    use Moose;

    has 'options' => (
       traits     => ['Array'],
       is         => 'ro',
       isa        => 'ArrayRef[Str]',
       default    => sub { [] },
       handles    => {
           all_options    => 'elements',
           add_option     => 'push',
           map_options    => 'map',
           filter_options => 'grep',
           find_option    => 'first',
           get_option     => 'get',
           join_options   => 'join',
           count_options  => 'count',
           has_options    => 'count',
           has_no_options => 'is_empty',
           sorted_options => 'sort',
       },
    );

    no Moose;
    1;

=head1 DESCRIPTION

This module provides an Array attribute which provides a number of
array operations.

=head1 PROVIDED METHODS

These methods are implemented in
L<Moose::Meta::Attribute::Native::MethodProvider::Array>.

=over 4

=item B<count>

Returns the number of elements in the array.

   $stuff = Stuff->new;
   $stuff->options(["foo", "bar", "baz", "boo"]);

   my $count = $stuff->count_options;
   print "$count\n"; # prints 4

=item B<is_empty>

Returns a boolean value that is true when the array has no elements.

   $stuff->has_no_options ? die "No options!\n" : print "Good boy.\n";

=item B<elements>

Returns all of the elements of the array.

   my @option = $stuff->all_options;
   print "@options\n"; # prints "foo bar baz boo"

=item B<get($index)>

Returns an element of the array by its index. You can also use negative index
numbers, just as with Perl's core array handling.

   my $option = $stuff->get_option(1);
   print "$option\n"; # prints "bar"

=item B<pop>

=item B<push($value1, $value2, value3 ...)>

=item B<shift>

=item B<unshift($value1, $value2, value3 ...)>

=item B<splice($offset, $length, @values)>

These methods are all equivalent to the Perl core functions of the same name.

=item B<first( sub { ... } )>

This method returns the first item matching item in the array, just like
L<List::Util>'s C<first> function. The matching is done with a subroutine
reference you pass to this method. The reference will be called against each
element in the array until one matches or all elements have been checked.

   my $found = $stuff->find_option( sub { /^b/ } );
   print "$found\n"; # prints "bar"

=item B<grep( sub { ... } )>

This method returns every element matching a given criteria, just like Perl's
core C<grep> function. This method requires a subroutine which implements the
matching logic.

   my @found = $stuff->filter_options( sub { /^b/ } );
   print "@found\n"; # prints "bar baz boo"

=item B<map( sub { ... } )>

This method transforms every element in the array and returns a new array,
just like Perl's core C<map> function. This method requires a subroutine which
implements the transformation.

   my @mod_options = $stuff->map_options( sub { $_ . "-tag" } );
   print "@mod_options\n"; # prints "foo-tag bar-tag baz-tag boo-tag"

=item B<reduce( sub { ... } )>

This method condenses an array into a single value, by passing a function the
value so far and the next value in the array, just like L<List::Util>'s
C<reduce> function. The reducing is done with a subroutine reference you pass
to this method.

   my $found = $stuff->reduce_options( sub { $_[0] . $_[1] } );
   print "$found\n"; # prints "foobarbazboo"

=item B<sort( sub { ... } )>

Returns a the array in sorted order.

You can provide an optional subroutine reference to sort with (as you can with
Perl's core C<sort> function). However, instead of using C<$a> and C<$b>, you
will need to use C<$_[0]> and C<$_[1]> instead.

   # ascending ASCIIbetical
   my @sorted = $stuff->sort_options();

   # Descending alphabetical order
   my @sorted_options = $stuff->sort_options( sub { lc $_[1] cmp lc $_[0] } );
   print "@sorted_options\n"; # prints "foo boo baz bar"

=item B<sort_in_place>

Sorts the array I<in place>, modifying the value of the attribute.

You can provide an optional subroutine reference to sort with (as you can with
Perl's core C<sort> function). However, instead of using C<$a> and C<$b>, you
will need to use C<$_[0]> and C<$_[1]> instead.

=item B<shuffle>

Returns the array, with indices in random order, like C<shuffle> from
L<List::Util>.

=item B<uniq>

Returns the array, with all duplicate elements removed, like C<uniq> from
L<List::MoreUtils>.

=item B<join($str)>

Joins every element of the array using the separator given as argument, just
like Perl's core C<join> function.

   my $joined = $stuff->join_options( ':' );
   print "$joined\n"; # prints "foo:bar:baz:boo"

=item B<set($index, $value)>

Given an index and a value, sets the specified array element's value.

=item B<delete($index)>

Removes the element at the given index from the array.

=item B<insert($index, $value)>

Inserts a new element into the array at the given index.

=item B<clear>

Empties the entire array, like C<@array = ()>.

=item B<accessor>

This method provides a get/set accessor for the array, based on array indexes.
If passed one argument, it returns the value at the specified index.  If
passed two arguments, it sets the value of the specified index.

=item B<natatime($n, $code)>

This method returns an iterator which, on each call, returns C<$n> more items
from the array, in order, like C<natatime> from L<List::MoreUtils>. A coderef
can optionally be provided; it will be called on each group of C<$n> elements
in the array.

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

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
