package Moose::Meta::TypeConstraint::Parameterizable;

use strict;
use warnings;
use metaclass;

our $VERSION   = '0.64';
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
            $contained_tc->is_a_type_of($parent->type_parameter)
             || Moose->throw_error("$type_parameter is not a subtype of ".$parent->type_parameter);
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
        Moose->throw_error("The type parameter must be a Moose meta type");
    }
}


1;

__END__


=pod

=head1 NAME

Moose::Meta::TypeConstraint::Parameterizable - Higher Order type constraints for Moose

=head1 METHODS

=over 4

=item B<constraint_generator>

=item B<has_constraint_generator>

=item B<generate_constraint_for>

=item B<parameterize>

Given a single type constraint string, this method parses the string
and parameterizes the type based on the parsed string.

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
