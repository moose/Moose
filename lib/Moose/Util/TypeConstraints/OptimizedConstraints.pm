package Moose::Util::TypeConstraints::OptimizedConstraints;

use strict;
use warnings;

use Scalar::Util 'blessed', 'looks_like_number';

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

use XSLoader;
# Optimized type constraints are XS in Moose.xs
XSLoader::load('Moose', '0.39'); # This is a pain... must use the version number of moose
                                 # but can't refer to it since Moose may not be loaded.

sub Num         { !Ref($_[0]) && looks_like_number($_[0]) }

sub Int         { Defined($_[0]) && !Ref($_[0]) && $_[0] =~ /^-?[0-9]+$/ }

sub FileHandle  { GlobRef($_[0]) && Scalar::Util::openhandle($_[0]) or ObjectOfType($_[0], "IO::Handle")  }

sub Role        { Object($_[0]) && $_[0]->can('does') }

1;

__END__

=pod

=head1 NAME

Moose::Util::TypeConstraints::OptimizedConstraints - Optimized constraint
bodies for various moose types

=head1 DESCRIPTION

This file contains the hand optimized versions of Moose type constraints.

=head1 FUNCTIONS

=over 4

=item Undef

=item Defined

=item Value

=item Ref

=item Str

=item Num

=item Int

=item ScalarRef

=item ArrayRef

=item HashRef

=item CodeRef

=item RegexpRef

=item GlobRef

=item FileHandle

=item Object

=item ObjectOfType

Makes sure $object->isa($class). Used in anon type constraints.

=item Role

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>
Konobi E<lt>konobi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
