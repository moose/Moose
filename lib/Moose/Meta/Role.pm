
package Moose::Meta::Role;

use strict;
use warnings;
use metaclass;

use Carp         'confess';
use Scalar::Util 'blessed';
use B            'svref_2object';

use Moose::Meta::Class;

our $VERSION = '0.04';

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

## excluded roles

__PACKAGE__->meta->add_attribute('excluded_roles_map' => (
    reader  => 'get_excluded_roles_map',
    default => sub { {} }
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

## Methods 

sub new {
    my $class   = shift;
    my %options = @_;
    $options{':role_meta'} = Moose::Meta::Class->initialize(
        $options{role_name},
        ':method_metaclass' => 'Moose::Meta::Role::Method'
    ) unless defined $options{':role_meta'} && 
             $options{':role_meta'}->isa('Moose::Meta::Class');
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

sub calculate_all_roles {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ } $self, map { $_->calculate_all_roles } @{ $self->get_roles };
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

## excluded roles

sub add_excluded_roles {
    my ($self, @excluded_role_names) = @_;
    $self->get_excluded_roles_map->{$_} = undef foreach @excluded_role_names;
}

sub get_excluded_roles_list {
    my ($self) = @_;
    keys %{$self->get_excluded_roles_map};
}

sub excludes_role {
    my ($self, $role_name) = @_;
    exists $self->get_excluded_roles_map->{$role_name} ? 1 : 0;
}

## required methods

sub add_required_methods {
    my ($self, @methods) = @_;
    $self->get_required_methods_map->{$_} = undef foreach @methods;
}

sub remove_required_methods {
    my ($self, @methods) = @_;
    delete $self->get_required_methods_map->{$_} foreach @methods;
}

sub get_required_method_list {
    my ($self) = @_;
    keys %{$self->get_required_methods_map};
}

sub requires_method {
    my ($self, $method_name) = @_;
    exists $self->get_required_methods_map->{$method_name} ? 1 : 0;
}

sub _clean_up_required_methods {
    my $self = shift;
    foreach my $method ($self->get_required_method_list) {
        $self->remove_required_methods($method)
            if $self->has_method($method);
    } 
}

## methods

# NOTE:
# we delegate to some role_meta methods for convience here
# the Moose::Meta::Role is meant to be a read-only interface
# to the underlying role package, if you want to manipulate 
# that, just use ->role_meta

sub name    { (shift)->_role_meta->name    }
sub version { (shift)->_role_meta->version }

sub get_method          { (shift)->_role_meta->get_method(@_)         }
sub find_method_by_name { (shift)->_role_meta->find_method_by_name(@_) }
sub has_method          { (shift)->_role_meta->has_method(@_)         }
sub alias_method        { (shift)->_role_meta->alias_method(@_)       }
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
    my $self = shift;
    my $name = shift;
    my $attr_desc;
    if (scalar @_ == 1 && ref($_[0]) eq 'HASH') {
        $attr_desc = $_[0];
    }
    else {
        $attr_desc = { @_ };
    }
    $self->get_attribute_map->{$name} = $attr_desc;
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


## applying a role to a class ...

sub _check_excluded_roles {
    my ($self, $other) = @_;
    if ($other->excludes_role($self->name)) {
        confess "Conflict detected: " . $other->name . " excludes role '" . $self->name . "'";
    }
    foreach my $excluded_role_name ($self->get_excluded_roles_list) {
        if ($other->does_role($excluded_role_name)) { 
            confess "The class " . $other->name . " does the excluded role '$excluded_role_name'";
        }
        else {
            if ($other->isa('Moose::Meta::Role')) {
                $other->add_excluded_roles($excluded_role_name);
            }
            # else -> ignore it :) 
        }
    }    
}

sub _check_required_methods {
    my ($self, $other) = @_;
    # NOTE:
    # we might need to move this down below the 
    # the attributes so that we can require any 
    # attribute accessors. However I am thinking 
    # that maybe those are somehow exempt from 
    # the require methods stuff.  
    foreach my $required_method_name ($self->get_required_method_list) {
        
        unless ($other->find_method_by_name($required_method_name)) {
            if ($other->isa('Moose::Meta::Role')) {
                $other->add_required_methods($required_method_name);
            }
            else {
                confess "'" . $self->name . "' requires the method '$required_method_name' " . 
                        "to be implemented by '" . $other->name . "'";
            }
        }
    }    
}

sub _apply_attributes {
    my ($self, $other) = @_;    
    foreach my $attribute_name ($self->get_attribute_list) {
        # it if it has one already
        if ($other->has_attribute($attribute_name) &&
            # make sure we haven't seen this one already too
            $other->get_attribute($attribute_name) != $self->get_attribute($attribute_name)) {
            # see if we are being composed  
            # into a role or not
            if ($other->isa('Moose::Meta::Role')) {                
                # all attribute conflicts between roles 
                # result in an immediate fatal error 
                confess "Role '" . $self->name . "' has encountered an attribute conflict " . 
                        "during composition. This is fatal error and cannot be disambiguated.";
            }
            else {
                # but if this is a class, we 
                # can safely skip adding the 
                # attribute to the class
                next;
            }
        }
        else {
            $other->add_attribute(
                $attribute_name,
                $self->get_attribute($attribute_name)
            );
        }
    }    
}

sub _apply_methods {
    my ($self, $other) = @_;   
    foreach my $method_name ($self->get_method_list) {
        # it if it has one already
        if ($other->has_method($method_name) &&
            # and if they are not the same thing ...
            $other->get_method($method_name) != $self->get_method($method_name)) {
            # see if we are composing into a role
            if ($other->isa('Moose::Meta::Role')) { 
                # method conflicts between roles result 
                # in the method becoming a requirement
                $other->add_required_methods($method_name);
                # NOTE:
                # we have to remove the method from our 
                # role, if this is being called from combine()
                # which means the meta is an anon class
                # this *may* cause problems later, but it 
                # is probably fairly safe to assume that 
                # anon classes will only be used internally
                # or by people who know what they are doing
                $other->_role_meta->remove_method($method_name)
                    if $other->_role_meta->name =~ /__ANON__/;
            }
            else {
                next;
            }
        }
        else {
            # add it, although it could be overriden 
            $other->alias_method(
                $method_name,
                $self->get_method($method_name)
            );
        }
    }     
}

sub apply {
    my ($self, $other) = @_;
    
    $self->_check_excluded_roles($other);
    $self->_check_required_methods($other);  

    $self->_apply_attributes($other);         
    $self->_apply_methods($other);         

    $other->add_role($self);
}

sub combine {
    my ($class, @roles) = @_;
    
    my $combined = $class->new(
        ':role_meta' => Moose::Meta::Class->create_anon_class()
    );
    
    foreach my $role (@roles) {
        $role->apply($combined);
    }
    
    $combined->_clean_up_required_methods;   
    
    return $combined;
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

=item B<combine>

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

=item B<add_excluded_roles>

=item B<excludes_role>

=item B<get_excluded_roles_list>

=item B<get_excluded_roles_map>

=item B<calculate_all_roles>

=back

=over 4

=item B<find_method_by_name>

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

=item B<remove_required_methods>

=item B<get_required_method_list>

=item B<get_required_methods_map>

=item B<requires_method>

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
