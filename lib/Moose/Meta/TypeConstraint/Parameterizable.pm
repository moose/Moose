package Moose::Meta::TypeConstraint::Parameterizable;

use strict;
use warnings;
use metaclass;

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';
use Moose::Meta::TypeConstraint::Parameterized;
use Moose::Util::TypeConstraints ();

__PACKAGE__->meta->add_attribute('constraint_generator' => (
    accessor  => 'constraint_generator',
    predicate => 'has_constraint_generator',
));

sub generate_constraint_for {
    my ($self, $type) = @_;

    return unless $self->has_constraint_generator;

    return $self->constraint_generator->($type->type_parameter)
        if $type->is_subtype_of($self->name);

    return $self->_can_coerce_constraint_from($type)
        if $self->has_coercion
        && $self->coercion->has_coercion_for_type($type->parent->name);

    return;
}

sub _can_coerce_constraint_from {
    my ($self, $type) = @_;
    my $coercion   = $self->coercion;
    my $constraint = $self->constraint_generator->($type->type_parameter);
    return sub {
        local $_ = $coercion->coerce($_);
        $constraint->(@_);
    };
}

sub _parse_type_parameter {
    my ($self, $type_parameter) = @_;
    return Moose::Util::TypeConstraints::find_or_create_isa_type_constraint($type_parameter);
}

sub parameterize {
    my ($self, $type_parameter) = @_;

    my $contained_tc = $self->_parse_type_parameter($type_parameter);

    ## The type parameter should be a subtype of the parent's type parameter
    ## if there is one.

    if(my $parent = $self->parent) {
        if($parent->can('type_parameter')) {
            unless ( $contained_tc->is_a_type_of($parent->type_parameter) ) {
                require Moose;
                Moose->throw_error("$type_parameter is not a subtype of ".$parent->type_parameter);
            }
        }
    }

    if ( $contained_tc->isa('Moose::Meta::TypeConstraint') ) {
        my $tc_name = $self->name . '[' . $contained_tc->name . ']';
        return Moose::Meta::TypeConstraint::Parameterized->new(
            name           => $tc_name,
            parent         => $self,
            type_parameter => $contained_tc,
        );
    }
    else {
        require Moose;
        Moose->throw_error("The type parameter must be a Moose meta type");
    }
}


1;

__END__


=pod

=head1 NAME

Moose::Meta::TypeConstraint::Parameterizable - Type constraints which can take a parameter (ArrayRef)

=head1 DESCRIPTION

This class represents a parameterizable type constraint. This is a
type constraint like C<ArrayRef> or C<HashRef>, that can be
parameterized and made more specific by specifying a contained
type. For example, instead of just an C<ArrayRef> of anything, you can
specify that is an C<ArrayRef[Int]>.

A parameterizable constraint should not be used as an attribute type
constraint. Instead, when parameterized it creates a
L<Moose::Meta::TypeConstraint::Parameterized> which should be used.

=head1 INHERITANCE

C<Moose::Meta::TypeConstraint::Parameterizable> is a subclass of
L<Moose::Meta::TypeConstraint>.

=head1 METHODS

This class is intentionally not documented because the API is
confusing and needs some work.

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
