
package Moose::Meta::Role::Method;

use strict;
use warnings;

our $VERSION   = '0.64';
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

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
