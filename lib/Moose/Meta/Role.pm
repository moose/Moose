
package Moose::Meta::Role;

use strict;
use warnings;
use metaclass;

use Carp 'confess';

our $VERSION = '0.02';

## the meta for the role package

__PACKAGE__->meta->add_attribute('role_meta' => (
    reader   => 'role_meta'
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

## method modifiers

__PACKAGE__->meta->add_attribute('before_method_modifiers' => (
    reader  => 'get_before_method_modifiers_map',
    default => sub { {} } # keyed by method name, then arrays of method-modifiers
));

__PACKAGE__->meta->add_attribute('after_method_modifiers' => (
    reader  => 'get_after_method_modifiers_map',
    default => sub { {} } # keyed by method name, then arrays of method-modifiers
));

__PACKAGE__->meta->add_attribute('around_method_modifiers' => (
    reader  => 'get_around_method_modifiers_map',
    default => sub { {} } # keyed by method name, then arrays of method-modifiers
));

__PACKAGE__->meta->add_attribute('override_method_modifiers' => (
    reader  => 'get_override_method_modifiers_map',
    default => sub { {} } # (<name> => CODE) 
));

## methods ...

sub new {
    my $class   = shift;
    my %options = @_;
    $options{'role_meta'} = Class::MOP::Class->initialize(
        $options{role_name},
        ':method_metaclass' => 'Moose::Meta::Role::Method'
    );
    my $self = $class->meta->new_object(%options);
    return $self;
}

sub apply {
    my ($self, $other) = @_;
    
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
    
    ## add the roles and set does()
    
    $other->add_role($self);
    
    # NOTE:
    # this will not replace a locally 
    # defined does() method, those 
    # should work as expected since 
    # they are working off the same 
    # metaclass. 
    # It will override an inherited 
    # does() method though, since 
    # it needs to add this new metaclass
    # to the mix.
    
    $other->add_method('does' => sub { 
        my (undef, $role_name) = @_;
        (defined $role_name)
            || confess "You much supply a role name to does()";
        foreach my $class ($other->class_precedence_list) {
            return 1 
                if $other->initialize($class)->does_role($role_name);            
        }
        return 0;
    }) unless $other->has_method('does');
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
    foreach my $role (@{$self->get_roles}) {
        return 1 if $role->name eq $role_name;
    }
    return 0;
}

## methods

# NOTE:
# we delegate to some role_meta methods for convience here
# the Moose::Meta::Role is meant to be a read-only interface
# to the underlying role package, if you want to manipulate 
# that, just use ->role_meta

sub name    { (shift)->role_meta->name    }
sub version { (shift)->role_meta->version }

sub get_method      { (shift)->role_meta->get_method(@_)  }
sub has_method      { (shift)->role_meta->has_method(@_)  }
sub get_method_list { 
    my ($self) = @_;
    # meta is not applicable in this context, 
    # if you want to see it use the ->role_meta
    grep { !/^meta$/ } $self->role_meta->get_method_list;
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
for more information. 

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