package Moose::Meta::TypeConstraint::Class;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use Moose::Util::TypeConstraints ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

sub new {
    my $class = shift;
    my $self  = $class->meta->new_object(@_, 
        parent => Moose::Util::TypeConstraints::find_type_constraint('Object') 
    );
    $self->compile_type_constraint()
        unless $self->_has_compiled_type_constraint;
    return $self;
}

sub parents {
    my $self = shift;
    return (
        $self->parent,
        map { 
            # NOTE:
            # Hmm, should this be find_or_create_type_constraint?
            # What do you think nothingmuch??
            # - SL
            Moose::Util::TypeConstraints::find_type_constraint($_) 
        } $self->name->meta->superclasses,
    );
}

sub hand_optimized_type_constraint {
    my $self  = shift;
    my $class = $self->name;
    sub { blessed( $_[0] ) && $_[0]->isa($class) }
}

sub has_hand_optimized_type_constraint { 1 }

sub is_a_type_of {
    my ($self, $type_name) = @_;

    return $self->name eq $type_name || $self->is_subtype_of($type_name);
}

sub is_subtype_of {
    my ($self, $type_name) = @_;

    return 1 if $type_name eq 'Object';
    return $self->name->isa( $type_name );
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Class - Class/TypeConstraint parallel hierarchy

=head1 METHODS

=over 4

=item B<new>

=item B<hand_optimized_type_constraint>

=item B<has_hand_optimized_type_constraint>

=item B<is_a_type_of>

=item B<is_subtype_of>

=item B<parents>

Return all the parent types, corresponding to the parent classes.

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
