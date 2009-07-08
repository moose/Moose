
package Moose::AttributeHelpers::Trait::Collection;
use Moose::Role;

our $VERSION   = '0.87';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

with 'Moose::AttributeHelpers::Trait::Base';

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::Collection - Base class for all collection type helpers

=head1 DESCRIPTION

Documentation to come.

=head1 METHODS

=over 4

=item B<meta>

=item B<container_type>

=item B<container_type_constraint>

=item B<has_container_type>

=item B<process_options_for_handles>

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
