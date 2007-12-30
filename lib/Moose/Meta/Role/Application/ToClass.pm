package Moose::Meta::Role::Application::ToClass;

use strict;
use warnings;
use metaclass;

use Carp            'confess';
use Scalar::Util    'blessed';

use Data::Dumper;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Role::Application';

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application::ToClass

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

