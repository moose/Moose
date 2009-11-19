package Moose::Util::TypeConstraints::OptimizedConstraints;

use strict;
use warnings;

use Class::MOP;
use Scalar::Util 'blessed', 'looks_like_number';

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub Value { defined($_[0]) && !ref($_[0]) }

sub Ref { ref($_[0]) }

sub Str { defined($_[0]) && ref(\$_[0]) eq 'SCALAR' }

sub Num { !ref($_[0]) && looks_like_number($_[0]) }

sub Int { defined($_[0]) && !ref($_[0]) && $_[0] =~ /^-?[0-9]+$/ }

sub ScalarRef { ref($_[0]) eq 'SCALAR' }
sub ArrayRef  { ref($_[0]) eq 'ARRAY'  }
sub HashRef   { ref($_[0]) eq 'HASH'   }
sub CodeRef   { ref($_[0]) eq 'CODE'   }
sub RegexpRef { ref($_[0]) eq 'Regexp' }
sub GlobRef   { ref($_[0]) eq 'GLOB'   }

sub FileHandle { ref($_[0]) eq 'GLOB' && Scalar::Util::openhandle($_[0]) or blessed($_[0]) && $_[0]->isa("IO::Handle") }

sub Object { blessed($_[0]) && blessed($_[0]) ne 'Regexp' }

sub Role { Carp::cluck('The Role type is deprecated.'); blessed($_[0]) && $_[0]->can('does') }

sub ClassName {
    return Class::MOP::is_class_loaded( $_[0] );
}

sub RoleName {
    ClassName($_[0])
    && (Class::MOP::class_of($_[0]) || return)->isa('Moose::Meta::Role')
}

# NOTE:
# we have XS versions too, ...
# 04:09 <@konobi> nothingmuch: konobi.co.uk/code/utilsxs.tar.gz
# 04:09 <@konobi> or utilxs.tar.gz iirc

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
