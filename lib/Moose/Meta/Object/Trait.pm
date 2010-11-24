
package Moose::Meta::Object::Trait;

use Scalar::Util qw(blessed);

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub _get_compatible_metaclass {
    my $orig = shift;
    my $self = shift;
    return $self->$orig(@_)
        || $self->_get_compatible_metaclass_by_role_reconciliation(@_);
}

sub _get_compatible_metaclass_by_role_reconciliation {
    my $self = shift;
    my ($other_name) = @_;
    my $meta_name = blessed($self) ? $self->_real_ref_name : $self;

    return unless Moose::Util::_classes_differ_by_roles_only(
        $meta_name, $other_name
    );

    return Moose::Util::_reconcile_roles_for_metaclass(
        $meta_name, $other_name
    );
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Object::Trait - Some overrides for L<Class::MOP::Object> functionality

=head1 DESCRIPTION

This module is entirely private, you shouldn't ever need to interact with
it directly.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
