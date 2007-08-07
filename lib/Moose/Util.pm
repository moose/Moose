package Moose::Util;

use Exporter qw/import/;
use Scalar::Util qw/blessed/;

use strict;
use warnings;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

our @EXPORT_OK = qw/can_role/;

sub can_role {
  my ($class,$does) = @_;

  return ((!ref $class && eval { $class->isa ('UNIVERSAL') }) || Scalar::Util::blessed ($class))
    && $class->can ('does')
    && $class->does ($does);
}

1;

__END__

=pod

=head1 NAME

Moose::Util - Moose utilities

=head1 SYNOPSIS

  use Moose::Util qw/can_role/;

  if (can_role ($object,'rolename')) {
    print "The object can do rolename!\n";
  }

=head1 FUNCTIONS

=over 4

=item can_role

  can_role ($object,$rolename);

Returns true if $object can do the role $rolename.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

