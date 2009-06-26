package Moose::AttributeHelpers::MethodProvider::List;
use Moose::Role;

our $VERSION   = '0.85';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub count : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        scalar @{ $reader->( $_[0] ) };
    };
}

sub empty : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        scalar @{ $reader->( $_[0] ) } ? 1 : 0;
    };
}

sub find : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $predicate ) = @_;
        foreach my $val ( @{ $reader->($instance) } ) {
            return $val if $predicate->($val);
        }
        return;
    };
}

sub map : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $f ) = @_;
        CORE::map { $f->($_) } @{ $reader->($instance) };
    };
}

sub sort : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $predicate ) = @_;
        die "Argument must be a code reference"
            if $predicate && ref $predicate ne 'CODE';

        if ($predicate) {
            CORE::sort { $predicate->( $a, $b ) } @{ $reader->($instance) };
        }
        else {
            CORE::sort @{ $reader->($instance) };
        }
    };
}

sub grep : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $predicate ) = @_;
        CORE::grep { $predicate->($_) } @{ $reader->($instance) };
    };
}

sub elements : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ($instance) = @_;
        @{ $reader->($instance) };
    };
}

sub join : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $separator ) = @_;
        join $separator, @{ $reader->($instance) };
    };
}

sub get : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        $reader->( $_[0] )->[ $_[1] ];
    };
}

sub first : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        $reader->( $_[0] )->[0];
    };
}

sub last : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        $reader->( $_[0] )->[-1];
    };
}

1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::MethodProvider::List

=head1 SYNOPSIS

   package Stuff;
   use Moose;
   use Moose::AttributeHelpers;

   has 'options' => (
       metaclass  => 'Collection::List',
       is         => 'rw',
       isa        => 'ArrayRef[Str]',
       default    => sub { [] },
       auto_deref => 1,
       handles   => {
           all_options       => 'elements',
           map_options       => 'map',
           filter_options    => 'grep',
           find_option       => 'find',
           first_option      => 'first',
           last_option       => 'last',
           get_option        => 'get',
           join_options      => 'join',
           count_options     => 'count',
           do_i_have_options => 'empty',
           sorted_options    => 'sort',
       }
   );

   no Moose;
   1;

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::AttributeHelpers::Collection::List>.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

=over 4

=item B<count>

Returns the number of elements in the list.

   $stuff = Stuff->new;
   $stuff->options(["foo", "bar", "baz", "boo"]);

   my $count = $stuff->count_options;
   print "$count\n"; # prints 4

=item B<empty>

If the list is populated, returns true. Otherwise, returns false.

   $stuff->do_i_have_options ? print "Good boy.\n" : die "No options!\n" ;

=item B<find>

This method accepts a subroutine reference as its argument. That sub
will receive each element of the list in turn. If it returns true for
an element, that element will be returned by the C<find> method.

   my $found = $stuff->find_option( sub { $_[0] =~ /^b/ } );
   print "$found\n"; # prints "bar"

=item B<grep>

This method accepts a subroutine reference as its argument. This
method returns every element for which that subroutine reference
returns a true value.

   my @found = $stuff->filter_options( sub { $_[0] =~ /^b/ } );
   print "@found\n"; # prints "bar baz boo"

=item B<map>

This method accepts a subroutine reference as its argument. The
subroutine will be executed for each element of the list. It is
expected to return a modified version of that element. The return
value of the method is a list of the modified options.

   my @mod_options = $stuff->map_options( sub { $_[0] . "-tag" } );
   print "@mod_options\n"; # prints "foo-tag bar-tag baz-tag boo-tag"

=item B<sort>

Sorts and returns the elements of the list.

You can provide an optional subroutine reference to sort with (as you
can with the core C<sort> function). However, instead of using C<$a>
and C<$b>, you will need to use C<$_[0]> and C<$_[1]> instead.

   # ascending ASCIIbetical
   my @sorted = $stuff->sort_options();

   # Descending alphabetical order
   my @sorted_options = $stuff->sort_options( sub { lc $_[1] cmp lc $_[0] } );
   print "@sorted_options\n"; # prints "foo boo baz bar"

=item B<elements>

Returns all of the elements of the list

   my @option = $stuff->all_options;
   print "@options\n"; # prints "foo bar baz boo"

=item B<join>

Joins every element of the list using the separator given as argument.

   my $joined = $stuff->join_options( ':' );
   print "$joined\n"; # prints "foo:bar:baz:boo"

=item B<get>

Returns an element of the list by its index.

   my $option = $stuff->get_option(1);
   print "$option\n"; # prints "bar"

=item B<first>

Returns the first element of the list.

   my $first = $stuff->first_option;
   print "$first\n"; # prints "foo"

=item B<last>

Returns the last element of the list.

   my $last = $stuff->last_option;
   print "$last\n"; # prints "boo"

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
