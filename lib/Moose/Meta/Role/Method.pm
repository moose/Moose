
package Moose::Meta::Role::Method;

use strict;
use warnings;

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method';

sub _make_compatible_with {
    my $self = shift;
    my ($other) = @_;

    # XXX: this is pretty gross. the issue here is blah blah blah
    # see the comments in CMOP::Method::Meta and CMOP::Method::Wrapped
    return $self unless $other->_is_compatible_with($self->_real_ref_name);

    return $self->SUPER::_make_compatible_with(@_);
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Method - A Moose Method metaclass for Roles

=head1 DESCRIPTION

This is primarily used to mark methods coming from a role
as being different. Right now it is nothing but a subclass
of L<Moose::Meta::Method>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
