
package Moose::Meta::TypeConstraint::Intersection;

use strict;
use warnings;
use metaclass;

use Moose::Meta::TypeCoercion::Intersection;

use List::Util qw(first);
use List::MoreUtils qw(all);

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('type_constraints' => (
    accessor  => 'type_constraints',
    default   => sub { [] },
    Class::MOP::_definition_context(),
));

sub new {
    my ($class, %options) = @_;

    my $name = join '&' => sort {$a cmp $b}
         map { $_->name } @{$options{type_constraints}};

    my $self = $class->SUPER::new(
        name     => $name,
        %options,
    );
    $self->_set_constraint(sub { $self->check($_[0]) });
    $self->coercion(Moose::Meta::TypeCoercion::Intersection->new(
        type_constraint => $self
    ));
    return $self;
}

sub _actually_compile_type_constraint {
    my $self = shift;

    my @constraints = @{ $self->type_constraints };

    return sub {
      my $value = shift;
      my $count = 0;
      foreach my $type (@constraints){
        $count++ if $type->check($value);
      }
      return $count==scalar @constraints ? 1: undef;
    };
}

sub can_be_inlined {
    my $self = shift;
    for my $tc ( @{ $self->type_constraints }) {
      return 0 unless $tc->can_be_inlined;
    }
    return 1;
}

sub _inline_check {
    my $self = shift;
    my $val  = shift;
    return '(' .
      (
        join ' && ' , map { '(' . $_->_inline_check($val) . ')' } @{ $self->type_constraints }
      ) . ')';
}

sub inline_environment {
    my $self = shift;

    return { map { %{ $_->inline_environment } } @{ $self->type_constraints } };
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

sub find_type_for {
    my ($self, $value) = @_;
    return first { $_->check($value) } @{ $self->type_constraints };
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

sub create_child_type {
    my ( $self, %opts ) = @_;

    my $constraint
        = Moose::Meta::TypeConstraint->new( %opts, parent => $self );

    # if we have a type constraint intersection, and no
    # type check, this means we are just aliasing
    # the intersection constraint, which means we need to
    # handle this differently.
    # - SL
    if ( not( defined $opts{constraint} )
        && $self->has_coercion ) {
        $constraint->coercion(
            Moose::Meta::TypeCoercion::Intersection->new(
                type_constraint => $self,
            )
        );
    }

    return $constraint;
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Intersection - An intersection of Moose type constraints

=head1 DESCRIPTION

This metaclass represents an intersection of Moose type constraints. More
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

=head2 Overridden methods

=over 4

=item B<check>

=item B<coerce>

=item B<validate>

=item B<is_a_type_of>

=item B<is_subtype_of>

=back

=head2 Empty or Stub methods

These methods tend to not be very relevant in
the context of an intersection. Either that or they are
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

=item B<create_child_type>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt> and
Adam Foxson E<lt>afoxson@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
