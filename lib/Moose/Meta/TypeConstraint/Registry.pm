
package Moose::Meta::TypeConstraint::Registry;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use Carp         'confess'; # FIXME Moose->throw_error

our $VERSION   = '0.64';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Class::MOP::Object';

__PACKAGE__->meta->add_attribute('parent_registry' => (
    reader    => 'get_parent_registry',
    writer    => 'set_parent_registry',    
    predicate => 'has_parent_registry',    
));

__PACKAGE__->meta->add_attribute('type_constraints' => (
    reader  => 'type_constraints',
    default => sub { {} }
));

sub new { 
    my $class = shift;
    my $self  = $class->_new(@_);
    return $self;
}

sub has_type_constraint {
    my ($self, $type_name) = @_;
    ($type_name and exists $self->type_constraints->{$type_name}) ? 1 : 0
}

sub get_type_constraint {
    my ($self, $type_name) = @_;
    return unless defined $type_name; 
    $self->type_constraints->{$type_name}
}

sub add_type_constraint {
    my ($self, $type) = @_;
    confess("No type supplied / type is not a valid type constraint") 
        unless ($type && blessed $type && $type->isa('Moose::Meta::TypeConstraint'));
    $self->type_constraints->{$type->name} = $type;
}

sub find_type_constraint {
    my ($self, $type_name) = @_;
    return $self->get_type_constraint($type_name)
        if $self->has_type_constraint($type_name);
    return $self->get_parent_registry->find_type_constraint($type_name)
        if $self->has_parent_registry;
    return;
}

1;

__END__


=pod

=head1 NAME

Moose::Meta::TypeConstraint::Registry - registry for type constraints

=head1 DESCRIPTION

This module is currently only use internally by L<Moose::Util::TypeConstraints>. 
It can be used to create your own private type constraint registry as well, but 
the details of that are currently left as an exercise to the reader. (One hint: 
You can use the 'parent_registry' feature to connect your private version with the 
base Moose registry and base Moose types will automagically be found too).

=head1 METHODS

=over 4

=item B<meta>

=item B<new>

=item B<get_parent_registry>

=item B<set_parent_registry ($registry)>
    
=item B<has_parent_registry>

=item B<type_constraints>

=item B<has_type_constraint ($type_name)>

=item B<get_type_constraint ($type_name)>

Returns a type constraint object from the registry by name. Will return
false if the supplied type name cannot be found.

=item B<add_type_constraint ($type)>

Adds a type constraint object to the registry. Will throw an exception if
no type is supplied, or the supplied object does not inherit from 
L<Moose::Meta::TypeConstraint>

=item B<find_type_constraint ($type_name)>

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
