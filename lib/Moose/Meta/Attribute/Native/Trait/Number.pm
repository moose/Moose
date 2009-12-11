package Moose::Meta::Attribute::Native::Trait::Number;
use Moose::Role;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

with 'Moose::Meta::Attribute::Native::Trait';

sub _helper_type { 'Num' }

# NOTE: we don't use the method provider for this module since many of
# the names of the provided methods would conflict with keywords - SL

has 'method_constructors' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        return +{
            set => sub {
                my ( $attr, $reader, $writer ) = @_;
                return sub { $writer->( $_[0], $_[1] ) };
            },
            add => sub {
                my ( $attr, $reader, $writer ) = @_;
                return sub { $writer->( $_[0], $reader->( $_[0] ) + $_[1] ) };
            },
            sub => sub {
                my ( $attr, $reader, $writer ) = @_;
                return sub { $writer->( $_[0], $reader->( $_[0] ) - $_[1] ) };
            },
            mul => sub {
                my ( $attr, $reader, $writer ) = @_;
                return sub { $writer->( $_[0], $reader->( $_[0] ) * $_[1] ) };
            },
            div => sub {
                my ( $attr, $reader, $writer ) = @_;
                return sub { $writer->( $_[0], $reader->( $_[0] ) / $_[1] ) };
            },
            mod => sub {
                my ( $attr, $reader, $writer ) = @_;
                return sub { $writer->( $_[0], $reader->( $_[0] ) % $_[1] ) };
            },
            abs => sub {
                my ( $attr, $reader, $writer ) = @_;
                return sub { $writer->( $_[0], abs( $reader->( $_[0] ) ) ) };
            },
        };
    }
);

no Moose::Role;

1;

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::Number - Helper trait for Num attributes

=head1 SYNOPSIS

  package Real;
  use Moose;

  has 'integer' => (
      traits    => ['Number'],
      is        => 'ro',
      isa       => 'Num',
      default   => 5,
      handles   => {
          set => 'set',
          add => 'add',
          sub => 'sub',
          mul => 'mul',
          div => 'div',
          mod => 'mod',
          abs => 'abs',
      },
  );

  my $real = Real->new();
  $real->add(5); # same as $real->integer($real->integer + 5);
  $real->sub(2); # same as $real->integer($real->integer - 2);

=head1 DESCRIPTION

This provides a simple numeric attribute, which supports most of the
basic math operations.

=head1 PROVIDED METHODS

It is important to note that all those methods do in place modification of the
value stored in the attribute. These methods are implemented within this
package.

=over 4

=item B<set($value)>

Alternate way to set the value.

=item B<add($value)>

Adds the current value of the attribute to C<$value>.

=item B<sub($value)>

Subtracts C<$value> from the current value of the attribute.

=item B<mul($value)>

Multiplies the current value of the attribute by C<$value>.

=item B<div($value)>

Divides the current value of the attribute by C<$value>.

=item B<mod($value)>

Returns the current value of the attribute modulo C<$value>.

=item B<abs>

Sets the current value of the attribute to its absolute value.

=back

=head1 METHODS

=over 4

=item B<meta>

=item B<method_constructors>

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
