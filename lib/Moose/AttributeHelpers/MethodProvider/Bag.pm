package Moose::AttributeHelpers::MethodProvider::Bag;
use Moose::Role;

our $VERSION   = '0.87';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

with 'Moose::AttributeHelpers::MethodProvider::ImmutableHash';

sub add : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $reader->( $_[0] )->{ $_[1] }++ };
}

sub delete : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { CORE::delete $reader->( $_[0] )->{ $_[1] } };
}

sub reset : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $reader->( $_[0] )->{ $_[1] } = 0 };
}

1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::MethodProvider::Bag

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::AttributeHelpers::Collection::Bag>.

This role is composed from the
L<Moose::AttributeHelpers::Collection::ImmutableHash> role.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

=over 4

=item B<count>

=item B<delete>

=item B<empty>

=item B<exists>

=item B<get>

=item B<keys>

=item B<add>

=item B<reset>

=item B<values>

=item B<kv>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

