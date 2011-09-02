package Moose::Meta::Method;

use strict;
use warnings;

use base 'Class::MOP::Method';

1;

# ABSTRACT: A Moose Method metaclass

__END__

=pod

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method> that provides
additional Moose-specific functionality, all of which is private.

To understand this class, you should read the the L<Class::MOP::Method>
documentation.

=head1 INHERITANCE

C<Moose::Meta::Method> is a subclass of L<Class::MOP::Method>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
