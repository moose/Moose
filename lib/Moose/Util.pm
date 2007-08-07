package Moose::Util;

use Exporter qw/import/;
use Scalar::Util qw/blessed/;

use strict;
use warnings;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

our @EXPORT_OK = qw/can_role search_class_by_role/;

sub can_role {
  my ($class,$does) = @_;

  return ((!ref $class && eval { $class->isa ('UNIVERSAL') }) || Scalar::Util::blessed ($class))
    && $class->can ('does')
    && $class->does ($does);
}

sub search_class_by_role {
    my ($obj, $role_name) = @_;

    for my $class ($obj->meta->class_precedence_list) {
        for my $role (@{ $class->meta->roles || [] }) {
            return $class if $role->name eq $role_name;
        }
    }

    return undef;
}

1;

__END__

=pod

=head1 NAME

Moose::Util - Moose utilities

=head1 SYNOPSIS

  use Moose::Util qw/can_role search_class_by_role/;

  if (can_role ($object,'rolename')) {
    print "The object can do rolename!\n";
  }

  my $class = search_class_by_role($object, 'FooRole');
  print "Nearest class with 'FooRole' is $class\n";

=head1 FUNCTIONS

=over 4

=item can_role

  can_role ($object,$rolename);

Returns true if $object can do the role $rolename.

=item search_class_by_role

  my $class = search_class_by_role($object, $rolename);

Returns first class in precedence list that consumed C<$rolename>.

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

