
package Moose::AttributeHelpers::Trait::Collection::ImmutableHash;
use Moose::Role;

our $VERSION   = '0.19';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::AttributeHelpers::MethodProvider::ImmutableHash;

with 'Moose::AttributeHelpers::Trait::Collection';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'Moose::AttributeHelpers::MethodProvider::ImmutableHash'
);

sub helper_type { 'HashRef' }

no Moose::Role;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Trait::Collection::ImmutableHash;
sub register_implementation {
    'Moose::AttributeHelpers::Trait::Collection::ImmutableHash'
}


1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::Collection::ImmutableHash

=head1 SYNOPSIS

  package Stuff;
  use Moose;
  use Moose::AttributeHelpers;

  has 'options' => (
      metaclass => 'Collection::ImmutableHash',
      is        => 'ro',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      provides  => {
          'get'    => 'get_option',
          'empty'  => 'has_options',
          'keys'   => 'get_option_list',
      }
  );

=head1 DESCRIPTION

This module provides a immutable HashRef attribute which provides a number of
hash-line operations. See L<Moose::AttributeHelpers::MethodProvider::ImmutableHash>
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
