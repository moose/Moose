package Moose::AttributeHelpers::Number;
use Moose;

our $VERSION   = '0.83';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Attribute';
with 'Moose::AttributeHelpers::Trait::Number';

no Moose;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Number;
sub register_implementation { 'Moose::AttributeHelpers::Number' }

1;

=pod

=head1 NAME

Moose::AttributeHelpers::Number

=head1 SYNOPSIS

  package Real;
  use Moose;
  use Moose::AttributeHelpers;

  has 'integer' => (
      metaclass => 'Number',
      is        => 'ro',
      isa       => 'Int',
      default   => sub { 5 },
      provides  => {
          set => 'set',
          add => 'add',
          sub => 'sub',
          mul => 'mul',
          div => 'div',
          mod => 'mod',
          abs => 'abs',
      }
  );

  my $real = Real->new();
  $real->add(5); # same as $real->integer($real->integer + 5);
  $real->sub(2); # same as $real->integer($real->integer - 2);

=head1 DESCRIPTION

This provides a simple numeric attribute, which supports most of the
basic math operations.

=head1 METHODS

=over 4

=item B<meta>

=item B<helper_type>

=item B<method_constructors>

=back

=head1 PROVIDED METHODS

It is important to note that all those methods do in place
modification of the value stored in the attribute.

=over 4

=item I<set ($value)>

Alternate way to set the value.

=item I<add ($value)>

Adds the current value of the attribute to C<$value>.

=item I<sub ($value)>

Subtracts the current value of the attribute to C<$value>.

=item I<mul ($value)>

Multiplies the current value of the attribute to C<$value>.

=item I<div ($value)>

Divides the current value of the attribute to C<$value>.

=item I<mod ($value)>

Modulus the current value of the attribute to C<$value>.

=item I<abs>

Sets the current value of the attribute to its absolute value.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Robert Boone

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
