
package Moose::Meta::Role::Method::Required;

use strict;
use warnings;
use metaclass;

use overload '""'     => sub { shift->name },   # stringify to method name
             fallback => 1;

use base qw(Class::MOP::Object);

our $VERSION   = '0.79';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

# This is not a Moose::Meta::Role::Method because it has no implementation, it
# is just a name

__PACKAGE__->meta->add_attribute('name' => (reader => 'name'));

sub new { shift->_new(@_) }

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Method::Required - A Moose metaclass for required methods in Roles

=head1 DESCRIPTION

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
