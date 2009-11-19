package Moose::Meta::Class::Immutable::Trait;

use strict;
use warnings;

use Class::MOP;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Class::MOP::Class::Immutable::Trait';

sub add_role { $_[1]->_immutable_cannot_call }

sub calculate_all_roles {
    my $orig = shift;
    my $self = shift;
    @{ $self->{__immutable}{calculate_all_roles} ||= [ $self->$orig ] };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Class::Immutable::Trait - Implements immutability for metaclass objects

=head1 DESCRIPTION

This class makes some Moose-specific metaclass methods immutable. This
is deep guts.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

