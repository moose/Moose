
package Moose::Meta::Role::Method::Conflicting;

use strict;
use warnings;

use Moose::Util;

use base qw(Moose::Meta::Role::Method::Required);

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

__PACKAGE__->meta->add_attribute('roles' => (
    reader   => 'roles',
    required => 1,
));

sub roles_as_english_list {
    my $self = shift;
    Moose::Util::english_list( map { q{'} . $_ . q{'} } @{ $self->roles } );
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Method::Conflicting - A Moose metaclass for conflicting methods in Roles

=head1 DESCRIPTION

=head1 INHERITANCE

C<Moose::Meta::Role::Method::Conflicting> is a subclass of
L<Moose::Meta::Role::Method::Required>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::Role::Method::Conflicting->new(%options) >>

This creates a new type constraint based on the provided C<%options>:

=over 8

=item * name

The method name. This is required.

=item * roles

The list of role names that generated the conflict. This is required.

=back

=item B<< $method->name >>

Returns the conflicting method's name, as provided to the constructor.

=item B<< $method->roles >>

Returns the roles that generated this conflicting method, as provided to the
constructor.

=item B<< $method->roles_as_english_list >>

Returns the roles that generated this conflicting method as an English list.

=back

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
