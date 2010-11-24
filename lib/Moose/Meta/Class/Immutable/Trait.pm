package Moose::Meta::Class::Immutable::Trait;

use strict;
use warnings;

use Class::MOP;
use Scalar::Util qw( blessed );

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Class::MOP::Class::Immutable::Trait';

sub add_role { $_[1]->_immutable_cannot_call }

sub calculate_all_roles {
    my $orig = shift;
    my $self = shift;
    @{ $self->{__immutable}{calculate_all_roles} ||= [ $self->$orig ] };
}

sub calculate_all_roles_with_inheritance {
    my $orig = shift;
    my $self = shift;
    @{ $self->{__immutable}{calculate_all_roles_with_inheritance} ||= [ $self->$orig ] };
}

sub does_role {
    shift;
    my $self = shift;
    my $role = shift;

    (defined $role)
        || $self->throw_error("You must supply a role name to look for");

    $self->{__immutable}{does_role} ||= { map { $_->name => 1 } $self->calculate_all_roles_with_inheritance };

    my $name = blessed $role ? $role->name : $role;

    return $self->{__immutable}{does_role}{$name};
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Class::Immutable::Trait - Implements immutability for metaclass objects

=head1 DESCRIPTION

This class makes some Moose-specific metaclass methods immutable. This
is deep guts.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

