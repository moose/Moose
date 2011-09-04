package Moose::Meta::Method::Constructor;

use strict;
use warnings;

use base 'Class::MOP::Method::Constructor', 'Moose::Meta::Method';

1;

# ABSTRACT: Method Meta Object for constructors

__END__

=pod

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Constructor> that
provides additional Moose-specific functionality

To understand this class, you should read the the
L<Class::MOP::Method::Constructor> documentation as well.

=head1 INHERITANCE

C<Moose::Meta::Method::Constructor> is a subclass of
L<Moose::Meta::Method> I<and> L<Class::MOP::Method::Constructor>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut

