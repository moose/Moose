
package Moose::Compiler::Engine;
use Moose::Role;

our $VERSION = '0.01';

requires 'compile_class';

1;

__END__

=pod

=head1 NAME

Moose::Compiler::Engine - An abstract roie for all Moose compiler engines

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<meta>

This will return the metaclass associated with the given role.

=back

=head1 REQUIRED METHODS

=over 4

=item B<compile_class>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut