
package Moose::AttributeHelpers::Collection::List;
use Moose;

our $VERSION   = '0.83';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Attribute';
with 'Moose::AttributeHelpers::Trait::Collection::List';

no Moose;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Collection::List;
sub register_implementation { 'Moose::AttributeHelpers::Collection::List' }


1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::Collection::List

=head1 SYNOPSIS

  package Stuff;
  use Moose;
  use Moose::AttributeHelpers;

  has 'options' => (
      metaclass => 'Collection::List',
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
list operations. See L<Moose::AttributeHelpers::MethodProvider::List>
for more details.

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=item B<helper_type>

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
