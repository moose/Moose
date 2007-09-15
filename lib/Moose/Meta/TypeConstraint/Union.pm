
package Moose::Meta::TypeConstraint::Union;

use strict;
use warnings;
use metaclass;

use Moose::Meta::TypeCoercion::Union;

our $VERSION   = '0.06';
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
details to be explained later (possibly in a Cookbook::Recipe).

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

=item B<constraint>

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

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
