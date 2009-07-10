
package Moose::Meta::Attribute::Trait::Native::List;
use Moose::Role;

our $VERSION   = '0.87';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Attribute::Trait::Native::MethodProvider::List;

with 'Moose::Meta::Attribute::Trait::Native::Collection';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'Moose::Meta::Attribute::Trait::Native::MethodProvider::List'
);

sub _helper_type { 'ArrayRef' }

no Moose::Role;

package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Trait::List;
sub register_implementation {
    'Moose::Meta::Attribute::Trait::Native::List'
}


1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Trait::Native::List

=head1 SYNOPSIS

  package Stuff;
  use Moose;
  use Moose::AttributeHelpers;

  has 'options' => (
      metaclass => 'List',
      is        => 'ro',
      isa       => 'ArrayRef[Int]',
      default   => sub { [] },
      handles   => {
          map_options    => 'map',
          filter_options => 'grep',
      }
  );

=head1 DESCRIPTION

This module provides an List attribute which provides a number of
list operations. See L<Moose::Meta::Attribute::Trait::Native::MethodProvider::List>
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
