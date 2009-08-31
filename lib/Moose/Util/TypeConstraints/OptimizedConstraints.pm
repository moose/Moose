package Moose::Util::TypeConstraints::OptimizedConstraints;

use strict;
use warnings;

use Moose ();

our $VERSION   = '0.89';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

# All the stuff are now in Moose.xs

1;

__END__

=pod

=head1 NAME

Moose::Util::TypeConstraints::OptimizedConstraints - Optimized constraint
bodies for various moose types

=head1 DESCRIPTION

This file contains the hand optimized versions of Moose type constraints,
no user serviceable parts inside.

=head1 FUNCTIONS

=over 4

=item C<Any>

=item C<Item>

=item C<Undef>

=item C<Defined>

=item C<Bool>

=item C<Value>

=item C<Ref>

=item C<Str>

=item C<Num>

=item C<Int>

=item C<ScalarRef>

=item C<ArrayRef>

=item C<HashRef>

=item C<CodeRef>

=item C<RegexpRef>

=item C<GlobRef>

=item C<FileHandle>

=item C<Object>

=item C<Role>

=item C<ClassName>

=item C<RoleName>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
