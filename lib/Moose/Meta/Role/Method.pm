
package Moose::Meta::Role::Method;

use strict;
use warnings;

our $VERSION   = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method';

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Method - A Moose Method metaclass for Roles

=head1 DESCRIPTION

This is primarily used to mark methods coming from a role
as being different. Right now it is nothing but a subclass
of L<Moose::Meta::Method>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
