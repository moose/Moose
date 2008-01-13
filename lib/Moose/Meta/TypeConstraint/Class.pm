package Moose::Meta::TypeConstraint::Class;

use strict;
use warnings;
use metaclass;

use Scalar::Util qw(blessed);

use base 'Moose::Meta::TypeConstraint';

use Moose::Util::TypeConstraints ();

sub new {
    my $class = shift;
    my $self  = $class->meta->new_object(@_, parent => Moose::Util::TypeConstraints::find_type_constraint('Object') );
    $self->compile_type_constraint()
        unless $self->_has_compiled_type_constraint;
    return $self;
}

sub parents {
    my $self = shift;
    return (
        $self->parent,
        map { Moose::Util::TypeConstraints::find_type_constraint($_) } $self->name->meta->superclasses,
    );
}

sub hand_optimized_type_constraint {
    my $self = shift;
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

=item new

=item hand_optimized_type_constraint

=item has_hand_optimized_type_constraint

=item is_a_type_of

=item is_subtype_of

=item parents

Return all the parent types, corresponding to the parent classes.

=back

=cut
