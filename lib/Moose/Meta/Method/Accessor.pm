
package Moose::Meta::Method::Accessor;

use strict;
use warnings;

use base 'Class::MOP::Method::Accessor', 'Moose::Meta::Method';

1;

# ABSTRACT: A Moose Method metaclass for accessors

__END__

=pod

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Accessor> that
provides additional Moose-specific functionality, all of which is
private.

To understand this class, you should read the the
L<Class::MOP::Method::Accessor> documentation.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
