
package Moose::Meta::TypeConstraint::Union;

use strict;
use warnings;
use metaclass;

use Moose::Meta::TypeCoercion::Union;

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('type_constraints' => (
    accessor  => 'type_constraints',
    default   => sub { [] }
));

sub new { 
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(
        name     => (join ' | ' => map { $_->name } @{$options{type_constraints}}),
        parent   => undef,
        message  => undef,
        hand_optimized_type_constraint => undef,
        compiled_type_constraint => sub {
            my $value = shift;
            foreach my $type (@{$options{type_constraints}}) {
                return 1 if $type->check($value);
            }
            return undef;    
        },
        %options
    );
    $self->_set_constraint(sub { $self->check($_[0]) });
    $self->coercion(Moose::Meta::TypeCoercion::Union->new(
        type_constraint => $self
    ));
    return $self;
}

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    return unless $other->isa(__PACKAGE__);

    my @self_constraints  = @{ $self->type_constraints };
    my @other_constraints = @{ $other->type_constraints };

    return unless @self_constraints == @other_constraints;

    # FIXME presort type constraints for efficiency?
    constraint: foreach my $constraint ( @self_constraints ) {
        for ( my $i = 0; $i < @other_constraints; $i++ ) {
            if ( $constraint->equals($other_constraints[$i]) ) {
                splice @other_constraints, $i, 1;
                next constraint;
            }
        }
    }

    return @other_constraints == 0;
}

sub parents {
    my $self = shift;
    $self->type_constraints;
}

sub validate {
    my ($self, $value) = @_;
    my $message;
    foreach my $type (@{$self->type_constraints}) {
        my $err = $type->validate($value);
        return unless defined $err;
        $message .= ($message ? ' and ' : '') . $err
            if defined $err;
    }
    return ($message . ' in (' . $self->name . ')') ;    
}

sub is_a_type_of {
    my ($self, $type_name) = @_;
    foreach my $type (@{$self->type_constraints}) {
        return 1 if $type->is_a_type_of($type_name);
    }
    return 0;    
}

sub is_subtype_of {
    my ($self, $type_name) = @_;
    foreach my $type (@{$self->type_constraints}) {
        return 1 if $type->is_subtype_of($type_name);
    }
    return 0;
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Union - A union of Moose type constraints

=head1 DESCRIPTION

This metaclass represents a union of Moose type constraints. More 
details to be explained later (possibly in a Cookbook recipe).

This actually used to be part of Moose::Meta::TypeConstraint, but it 
is now better off in it's own file. 

=head1 METHODS

This class is not a subclass of Moose::Meta::TypeConstraint, 
but it does provide the same API

=over 4

=item B<meta>

=item B<new>

=item B<name>

=item B<type_constraints>

=item B<parents>

=item B<constraint>

=item B<includes_type>

=item B<equals>

=back

=head2 Overriden methods 

=over 4

=item B<check>

=item B<coerce>

=item B<validate>

=item B<is_a_type_of>

=item B<is_subtype_of>

=back

=head2 Empty or Stub methods

These methods tend to not be very relevant in 
the context of a union. Either that or they are 
just difficult to specify and not very useful 
anyway. They are here for completeness.

=over 4

=item B<parent>

=item B<coercion>

=item B<has_coercion>

=item B<message>

=item B<has_message>

=item B<hand_optimized_type_constraint>

=item B<has_hand_optimized_type_constraint>

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
