package Moose::Meta::TypeConstraint::Class;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use Moose::Util::TypeConstraints ();

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('class' => (
    reader => 'class',
));

sub new {
    my ( $class, %args ) = @_;

    $args{parent} = Moose::Util::TypeConstraints::find_type_constraint('Object');
    my $self      = $class->_new(\%args);

    $self->_create_hand_optimized_type_constraint;
    $self->compile_type_constraint();

    return $self;
}

sub _create_hand_optimized_type_constraint {
    my $self = shift;
    my $class = $self->class;
    $self->hand_optimized_type_constraint(
        sub { 
            blessed( $_[0] ) && $_[0]->isa($class) 
        }
    );
}

sub parents {
    my $self = shift;
    return (
        $self->parent,
        map {
            # FIXME find_type_constraint might find a TC named after the class but that isn't really it
            # I did this anyway since it's a convention that preceded TypeConstraint::Class, and it should DWIM
            # if anybody thinks this problematic please discuss on IRC.
            # a possible fix is to add by attr indexing to the type registry to find types of a certain property
            # regardless of their name
            Moose::Util::TypeConstraints::find_type_constraint($_) 
                || 
            __PACKAGE__->new( class => $_, name => "__ANON__" )
        } $self->class->meta->superclasses,
    );
}

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    return unless $other->isa(__PACKAGE__);

    return $self->class eq $other->class;
}

sub is_a_type_of {
    my ($self, $type_or_name) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    ($self->equals($type) || $self->is_subtype_of($type_or_name));
}

sub is_subtype_of {
    my ($self, $type_or_name_or_class ) = @_;

    if ( not ref $type_or_name_or_class ) {
        # it might be a class
        return 1 if $self->class->isa( $type_or_name_or_class );
    }

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name_or_class);

    if ( $type->isa(__PACKAGE__) ) {
        # if $type_or_name_or_class isn't a class, it might be the TC name of another ::Class type
        # or it could also just be a type object in this branch
        return $self->class->isa( $type->class );
    } else {
        # the only other thing we are a subtype of is Object
        $self->SUPER::is_subtype_of($type);
    }
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Class - Class/TypeConstraint parallel hierarchy

=head1 METHODS

=over 4

=item B<new>

=item B<class>

=item B<hand_optimized_type_constraint>

=item B<has_hand_optimized_type_constraint>

=item B<equals>

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
