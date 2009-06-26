
package Moose::AttributeHelpers::Collection::Hash;
use Moose;

our $VERSION   = '0.83';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Attribute';
with 'Moose::AttributeHelpers::Trait::Collection::Hash';

no Moose;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Collection::Hash;
sub register_implementation { 'Moose::AttributeHelpers::Collection::Hash' }


1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::Collection::Hash

=head1 SYNOPSIS

  package Stuff;
  use Moose;
  use Moose::AttributeHelpers;

  has 'options' => (
      metaclass => 'Collection::Hash',
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
hash-like operations. See L<Moose::AttributeHelpers::MethodProvider::Hash>
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
