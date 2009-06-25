
package Moose::AttributeHelpers::String;
use Moose;

our $VERSION   = '0.19';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Attribute';
with 'Moose::AttributeHelpers::Trait::String';

no Moose;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::String;
sub register_implementation { 'Moose::AttributeHelpers::String' }

1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::String

=head1 SYNOPSIS

  package MyHomePage;
  use Moose;
  use Moose::AttributeHelpers;

  has 'text' => (
      metaclass => 'String',
      is        => 'rw',
      isa       => 'Str',
      default   => sub { '' },
      provides  => {
          append => "add_text",
          replace => "replace_text",
      }
  );

  my $page = MyHomePage->new();
  $page->add_text("foo"); # same as $page->text($page->text . "foo");

=head1 DESCRIPTION

This module provides a simple string attribute, to which mutating string
operations can be applied more easily (no need to make an lvalue attribute
metaclass or use temporary variables). Additional methods are provided for
completion.

If your attribute definition does not include any of I<is>, I<isa>,
I<default> or I<provides> but does use the C<String> metaclass,
then this module applies defaults as in the L</SYNOPSIS>
above. This allows for a very basic counter definition:

  has 'foo' => (metaclass => 'String');
  $obj->append_foo;

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=item B<helper_type>

=item B<process_options_for_handles>

Run before its superclass method.

=item B<check_handles_values>

Run after its superclass method.

=back

=head1 PROVIDED METHODS

It is important to note that all those methods do in place
modification of the value stored in the attribute.

=over 4

=item I<inc>

Increments the value stored in this slot using the magical string autoincrement
operator. Note that Perl doesn't provide analogeous behavior in C<-->, so
C<dec> is not available.

=item I<append> C<$string>

Append a string, like C<.=>.

=item I<prepend> C<$string>

Prepend a string.

=item I<replace> C<$pattern> C<$replacement>

Performs a regexp substitution (L<perlop/s>). There is no way to provide the
C<g> flag, but code references will be accepted for the replacement, causing
the regex to be modified with a single C<e>. C</smxi> can be applied using the
C<qr> operator.

=item I<match> C<$pattern>

Like I<replace> but without the replacement. Provided mostly for completeness.

=item C<chop>

L<perlfunc/chop>

=item C<chomp>

L<perlfunc/chomp>

=item C<clear>

Sets the string to the empty string (not the value passed to C<default>).

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
