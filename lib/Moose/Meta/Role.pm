
package Moose::Meta::Role;

use strict;
use warnings;
use metaclass;

use Carp         'confess';
use Scalar::Util 'blessed';

use Moose::Meta::Class;

our $VERSION = '0.02';

## Attributes

## the meta for the role package

__PACKAGE__->meta->add_attribute('_role_meta' => (
    reader   => '_role_meta',
    init_arg => ':role_meta'
));

## roles

__PACKAGE__->meta->add_attribute('roles' => (
    reader  => 'get_roles',
    default => sub { [] }
));

## attributes

__PACKAGE__->meta->add_attribute('attribute_map' => (
    reader   => 'get_attribute_map',
    default  => sub { {} }
));

## required methods

__PACKAGE__->meta->add_attribute('required_methods' => (
    reader  => 'get_required_methods_map',
    default => sub { {} }
));

## method modifiers

__PACKAGE__->meta->add_attribute('before_method_modifiers' => (
    reader  => 'get_before_method_modifiers_map',
    default => sub { {} } # (<name> => [ (CODE) ])
));

__PACKAGE__->meta->add_attribute('after_method_modifiers' => (
    reader  => 'get_after_method_modifiers_map',
    default => sub { {} } # (<name> => [ (CODE) ])
));

__PACKAGE__->meta->add_attribute('around_method_modifiers' => (
    reader  => 'get_around_method_modifiers_map',
    default => sub { {} } # (<name> => [ (CODE) ])
));

__PACKAGE__->meta->add_attribute('override_method_modifiers' => (
    reader  => 'get_override_method_modifiers_map',
    default => sub { {} } # (<name> => CODE) 
));

## Methods 

sub new {
    my $class   = shift;
    my %options = @_;
    $options{':role_meta'} = Moose::Meta::Class->initialize(
        $options{role_name},
        ':method_metaclass' => 'Moose::Meta::Role::Method'
    );
    my $self = $class->meta->new_object(%options);
    return $self;
}

## subroles

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || confess "Roles must be instances of Moose::Meta::Role";
    push @{$self->get_roles} => $role;
}

sub does_role {
    my ($self, $role_name) = @_;
    (defined $role_name)
        || confess "You must supply a role name to look for";
    # if we are it,.. then return true
    return 1 if $role_name eq $self->name;
    # otherwise.. check our children
    foreach my $role (@{$self->get_roles}) {
        return 1 if $role->does_role($role_name);
    }
    return 0;
}

## required methods

sub add_required_methods {
    my ($self, @methods) = @_;
    $self->get_required_methods_map->{$_} = undef foreach @methods;
}

sub get_required_method_list {
    my ($self) = @_;
    keys %{$self->get_required_methods_map};
}

sub requires_method {
    my ($self, $method_name) = @_;
    exists $self->get_required_methods_map->{$method_name} ? 1 : 0;
}

## methods

# NOTE:
# we delegate to some role_meta methods for convience here
# the Moose::Meta::Role is meant to be a read-only interface
# to the underlying role package, if you want to manipulate 
# that, just use ->role_meta

sub name    { (shift)->_role_meta->name    }
sub version { (shift)->_role_meta->version }

sub get_method      { (shift)->_role_meta->get_method(@_)   }
sub has_method      { (shift)->_role_meta->has_method(@_)   }
sub alias_method    { (shift)->_role_meta->alias_method(@_) }
sub get_method_list { 
    my ($self) = @_;
    grep { 
        # NOTE:
        # this is a kludge for now,... these functions 
        # should not be showing up in the list at all, 
        # but they do, so we need to switch Moose::Role
        # and Moose to use Sub::Exporter to prevent this
        !/^(meta|has|extends|blessed|confess|augment|inner|override|super|before|after|around|with|requires)$/ 
    } $self->_role_meta->get_method_list;
}

# ... however the items in statis (attributes & method modifiers)
# can be removed and added to through this API

# attributes

sub add_attribute {
    my ($self, $name, %attr_desc) = @_;
    $self->get_attribute_map->{$name} = \%attr_desc;
}

sub has_attribute {
    my ($self, $name) = @_;
    exists $self->get_attribute_map->{$name} ? 1 : 0;
}

sub get_attribute {
    my ($self, $name) = @_;
    $self->get_attribute_map->{$name}
}

sub remove_attribute {
    my ($self, $name) = @_;
    delete $self->get_attribute_map->{$name}
}

sub get_attribute_list {
    my ($self) = @_;
    keys %{$self->get_attribute_map};
}

# method modifiers

# mimic the metaclass API
sub add_before_method_modifier { (shift)->_add_method_modifier('before', @_) }
sub add_around_method_modifier { (shift)->_add_method_modifier('around', @_) }
sub add_after_method_modifier  { (shift)->_add_method_modifier('after',  @_) }

sub _add_method_modifier {
    my ($self, $modifier_type, $method_name, $method) = @_;
    my $accessor = "get_${modifier_type}_method_modifiers_map";
    $self->$accessor->{$method_name} = [] 
        unless exists $self->$accessor->{$method_name};
    push @{$self->$accessor->{$method_name}} => $method;
}

sub add_override_method_modifier {
    my ($self, $method_name, $method) = @_;
    $self->get_override_method_modifiers_map->{$method_name} = $method;    
}

sub has_before_method_modifiers { (shift)->_has_method_modifiers('before', @_) }
sub has_around_method_modifiers { (shift)->_has_method_modifiers('around', @_) }
sub has_after_method_modifiers  { (shift)->_has_method_modifiers('after',  @_) }

# override just checks for one,.. 
# but we can still re-use stuff
sub has_override_method_modifier { (shift)->_has_method_modifiers('override',  @_) }

sub _has_method_modifiers {
    my ($self, $modifier_type, $method_name) = @_;
    my $accessor = "get_${modifier_type}_method_modifiers_map";   
    # NOTE:
    # for now we assume that if it exists,.. 
    # it has at least one modifier in it
    (exists $self->$accessor->{$method_name}) ? 1 : 0;
}

sub get_before_method_modifiers { (shift)->_get_method_modifiers('before', @_) }
sub get_around_method_modifiers { (shift)->_get_method_modifiers('around', @_) }
sub get_after_method_modifiers  { (shift)->_get_method_modifiers('after',  @_) }

sub _get_method_modifiers {
    my ($self, $modifier_type, $method_name) = @_;
    my $accessor = "get_${modifier_type}_method_modifiers_map";
    @{$self->$accessor->{$method_name}};
}

sub get_override_method_modifier {
    my ($self, $method_name) = @_;
    $self->get_override_method_modifiers_map->{$method_name};    
}

sub get_method_modifier_list {
    my ($self, $modifier_type) = @_;
    my $accessor = "get_${modifier_type}_method_modifiers_map";    
    keys %{$self->$accessor};
}

## applying a role to a class ...

sub apply {
    my ($self, $other) = @_;
    
    # NOTE:
    # we might need to move this down below the 
    # the attributes so that we can require any 
    # attribute accessors. However I am thinking 
    # that maybe those are somehow exempt from 
    # the require methods stuff.  
    foreach my $required_method_name ($self->get_required_method_list) {
        unless ($other->has_method($required_method_name)) {
            if ($other->isa('Moose::Meta::Role')) {
                $other->add_required_methods($required_method_name);
            }
            else {
                confess "'" . $self->name . "' requires the method '$required_method_name' " . 
                        "to be implemented by '" . $other->name . "'";
            }
        }
    }    
    
    foreach my $attribute_name ($self->get_attribute_list) {
        # skip it if it has one already
        next if $other->has_attribute($attribute_name);
        # add it, although it could be overriden 
        $other->add_attribute(
            $attribute_name,
            %{$self->get_attribute($attribute_name)}
        );
    }
    
    foreach my $method_name ($self->get_method_list) {
        # skip it if it has one already
        next if $other->has_method($method_name);
        # add it, although it could be overriden 
        $other->alias_method(
            $method_name,
            $self->get_method($method_name)
        );
    }    
    
    foreach my $method_name ($self->get_method_modifier_list('override')) {
        # skip it if it has one already
        next if $other->has_method($method_name);
        # add it, although it could be overriden 
        $other->add_override_method_modifier(
            $method_name,
            $self->get_override_method_modifier($method_name),
            $self->name
        );
    }    
    
    foreach my $method_name ($self->get_method_modifier_list('before')) {
        $other->add_before_method_modifier(
            $method_name,
            $_
        ) foreach $self->get_before_method_modifiers($method_name);
    }    
    
    foreach my $method_name ($self->get_method_modifier_list('after')) {
        $other->add_after_method_modifier(
            $method_name,
            $_
        ) foreach $self->get_after_method_modifiers($method_name);
    }    
    
    foreach my $method_name ($self->get_method_modifier_list('around')) {
        $other->add_around_method_modifier(
            $method_name,
            $_
        ) foreach $self->get_around_method_modifiers($method_name);
    }    
    
    $other->add_role($self);
}

package Moose::Meta::Role::Method;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Class::MOP::Method';

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role - The Moose Role metaclass

=head1 DESCRIPTION

Moose's Roles are being actively developed, please see L<Moose::Role> 
for more information. For the most part, this has no user-serviceable 
parts inside. It's API is still subject to some change (although 
probably not that much really).

=head1 METHODS

=over 4

=item B<meta>

=item B<new>

=item B<apply>

=back

=over 4

=item B<name>

=item B<version>

=item B<role_meta>

=back

=over 4

=item B<get_roles>

=item B<add_role>

=item B<does_role>

=back

=over 4

=item B<get_method>

=item B<has_method>

=item B<alias_method>

=item B<get_method_list>

=back

=over 4

=item B<add_attribute>

=item B<has_attribute>

=item B<get_attribute>

=item B<get_attribute_list>

=item B<get_attribute_map>

=item B<remove_attribute>

=back

=over 4

=item B<add_required_methods>

=item B<get_required_method_list>

=item B<get_required_methods_map>

=item B<requires_method>

=back

=over 4

=item B<add_after_method_modifier>

=item B<add_around_method_modifier>

=item B<add_before_method_modifier>

=item B<add_override_method_modifier>

=over 4

=back

=item B<has_after_method_modifiers>

=item B<has_around_method_modifiers>

=item B<has_before_method_modifiers>

=item B<has_override_method_modifier>

=over 4

=back

=item B<get_after_method_modifiers>

=item B<get_around_method_modifiers>

=item B<get_before_method_modifiers>

=item B<get_method_modifier_list>

=over 4

=back

=item B<get_override_method_modifier>

=item B<get_after_method_modifiers_map>

=item B<get_around_method_modifiers_map>

=item B<get_before_method_modifiers_map>

=item B<get_override_method_modifiers_map>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut