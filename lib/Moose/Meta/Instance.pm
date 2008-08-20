
package Moose::Meta::Instance;

use strict;
use warnings;

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base "Class::MOP::Instance";

1;

__END__

=pod

=head1 NAME

Moose::Meta::Instance - The Moose Instance metaclass

=head1 SYNOPSIS

    # nothing to see here

=head1 DESCRIPTION

This class provides the low level data storage abstractions for attributes.

Using this API generally violates attribute encapsulation and is not
recommended, instead look at L<Class::MOP::Attribute/get_value>,
L<Class::MOP::Attribute/set_value>, etc, as well as L<Moose::Meta::Attribute>
for the recommended way to fiddle with attribute values in a generic way,
independent of how/whether accessors have been defined. Accessors can be found
using L<Class::MOP::Class/get_attribute>.

See the L<Class::MOP::Instance> docs for details on the instance protocol.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
