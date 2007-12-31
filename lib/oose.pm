package oose;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

BEGIN {
    my $package;
    sub import { $package = $_[1] }
    use Filter::Simple sub { s/^/package $package;\nuse Moose;\n/; }
}

1;

__END__

=pod

=head1 NAME

oose - syntactic sugar to make Moose one-liners easier

=head1 SYNOPSIS

    perl -Moose=Foo -e 'has bar => ( is=>q[ro], default => q[baz] ); print Foo->new->bar' # prints baz

=head1 DESCRIPTION

oose.pm is a simple source filter that adds C<package $name; use Moose;> 
to the beginning of your script and was entirely created because typing 
perl -e'package Foo; use Moose; ...' was annoying me.

=head1 INTERFACE 

oose provides exactly one method and it's automically called by perl:

=over 4

=item B<import($package)>

Pass a package name to import to be used by the source filter.

=back

=head1 DEPENDENCIES

You will need L<Filter::Simple> and eventually L<Moose>

=head1 INCOMPATIBILITIES

None reported. But it is a source filter and might have issues there.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Chris Prather  C<< <perigrin@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
