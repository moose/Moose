
package Moose::Meta::Attribute::Trait::Native::Hash;
use Moose::Role;

our $VERSION   = '0.87';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Attribute::Trait::Native::MethodProvider::Hash;

with 'Moose::Meta::Attribute::Trait::Native::Collection';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'Moose::Meta::Attribute::Trait::Native::MethodProvider::Hash'
);

sub _helper_type { 'HashRef' }

no Moose::Role;

package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Trait::Hash;
sub register_implementation {
    'Moose::Meta::Attribute::Trait::Native::Hash'
}


1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Trait::Native::Hash

=head1 SYNOPSIS

  package Stuff;
  use Moose;
  use Moose::AttributeHelpers;

  has 'options' => (
      metaclass => 'Hash',
      is        => 'ro',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      handles   => {
          set_option    => 'set',
          get_option    => 'get',
          has_options   => 'empty',
          num_options   => 'count',
          delete_option => 'delete',
      }
  );

=head1 DESCRIPTION

This module provides a Hash attribute which provides a number of
hash-like operations. See L<Moose::Meta::Attribute::Trait::Native::MethodProvider::Hash>
for more details.

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
