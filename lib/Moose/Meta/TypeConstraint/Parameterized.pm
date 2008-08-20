package Moose::Meta::TypeConstraint::Parameterized;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use Carp         'confess';
use Moose::Util::TypeConstraints;

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('type_parameter' => (
    accessor  => 'type_parameter',
    predicate => 'has_type_parameter',
));

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    return unless $other->isa(__PACKAGE__);
    
    return (
        $self->type_parameter->equals( $other->type_parameter )
            and
        $self->parent->equals( $other->parent )
    );
}

sub compile_type_constraint {
    my $self = shift;
    
    ($self->has_type_parameter)
        || confess "You cannot create a Higher Order type without a type parameter";
        
    my $type_parameter = $self->type_parameter;
    
    (blessed $type_parameter && $type_parameter->isa('Moose::Meta::TypeConstraint'))
        || confess "The type parameter must be a Moose meta type";

    foreach my $type (Moose::Util::TypeConstraints::get_all_parameterizable_types()) {
        if (my $constraint = $type->generate_constraint_for($self)) {
            $self->_set_constraint($constraint);
            return $self->SUPER::compile_type_constraint;            
        }
    }
    
    # if we get here, then we couldn't 
    # find a way to parameterize this type
    confess "The " . $self->name . " constraint cannot be used, because " 
          . $self->parent->name . " doesn't subtype or coerce from a parameterizable type.";
}

1;

__END__


=pod

=head1 NAME

Moose::Meta::TypeConstraint::Parameterized - Higher Order type constraints for Moose

=head1 METHODS

=over 4

=item B<compile_type_constraint>

=item B<type_parameter>

=item B<has_type_parameter>

=item B<meta>

=item B<equals>

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
