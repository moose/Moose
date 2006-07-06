
package Moose::Meta::Class;

use strict;
use warnings;

use Class::MOP;

use Carp         'confess';
use Scalar::Util 'weaken', 'blessed', 'reftype';

our $VERSION = '0.07';

use base 'Class::MOP::Class';

__PACKAGE__->meta->add_attribute('roles' => (
    reader  => 'roles',
    default => sub { [] }
));

sub initialize {
    my $class = shift;
    my $pkg   = shift;
    $class->SUPER::initialize($pkg,
        ':attribute_metaclass' => 'Moose::Meta::Attribute', 
        ':instance_metaclass'  => 'Moose::Meta::Instance', 
        @_);
}  

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || confess "Roles must be instances of Moose::Meta::Role";
    push @{$self->roles} => $role;
}

sub calculate_all_roles {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ } map { $_->calculate_all_roles } @{ $self->roles };
}

sub does_role {
    my ($self, $role_name) = @_;
    (defined $role_name)
        || confess "You must supply a role name to look for";
    foreach my $class ($self->class_precedence_list) {
        next unless $class->can('meta');        
        foreach my $role (@{$class->meta->roles}) {
            return 1 if $role->does_role($role_name);
        }
    }
    return 0;
}

sub excludes_role {
    my ($self, $role_name) = @_;
    (defined $role_name)
        || confess "You must supply a role name to look for";
    foreach my $class ($self->class_precedence_list) {  
        next unless $class->can('meta');      
        foreach my $role (@{$class->meta->roles}) {
            return 1 if $role->excludes_role($role_name);
        }
    }
    return 0;
}

sub new_object {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new_object(%params);
    foreach my $attr ($class->compute_all_applicable_attributes()) {
        # FIXME:
        # this does not accept undefined
        # values, nor does it accept false 
        # values to be passed into the init-arg
        next unless $params{$attr->init_arg} && $attr->can('has_trigger') && $attr->has_trigger;
        $attr->trigger->($self, $params{$attr->init_arg}, $attr);
    }
    return $self;    
}

sub construct_instance {
    my ($class, %params) = @_;
    my $meta_instance = $class->get_meta_instance;
    # FIXME:
    # the code below is almost certainly incorrect
    # but this is foreign inheritence, so we might
    # have to kludge it in the end. 
    my $instance = $params{'__INSTANCE__'} || $meta_instance->create_instance();
    foreach my $attr ($class->compute_all_applicable_attributes()) { 
        $attr->initialize_instance_slot($meta_instance, $instance, \%params)
    }
    return $instance;
}

sub has_method {
    my ($self, $method_name) = @_;
    (defined $method_name && $method_name)
        || confess "You must define a method name";    

    my $sub_name = ($self->name . '::' . $method_name);   
    
    no strict 'refs';
    return 0 if !defined(&{$sub_name});        
	my $method = \&{$sub_name};
	
	return 1 if blessed($method) && $method->isa('Moose::Meta::Role::Method');
    return $self->SUPER::has_method($method_name);    
}

sub add_attribute {
    my $self = shift;
    my $name = shift;
    if (scalar @_ == 1 && ref($_[0]) eq 'HASH') {
        # NOTE:
        # if it is a HASH ref, we de-ref it.        
        # this will usually mean that it is 
        # coming from a role
        $self->SUPER::add_attribute($name => %{$_[0]});
    }
    else {
        # otherwise we just pass the args
        $self->SUPER::add_attribute($name => @_);
    }
}

sub add_override_method_modifier {
    my ($self, $name, $method, $_super_package) = @_;
    (!$self->has_method($name))
        || confess "Cannot add an override method if a local method is already present";
    # need this for roles ...
    $_super_package ||= $self->name;
    my $super = $self->find_next_method_by_name($name);
    (defined $super)
        || confess "You cannot override '$name' because it has no super method";    
    $self->add_method($name => bless sub {
        my @args = @_;
        no strict   'refs';
        no warnings 'redefine';
        local *{$_super_package . '::super'} = sub { $super->(@args) };
        return $method->(@args);
    } => 'Moose::Meta::Method::Overriden');
}

sub add_augment_method_modifier {
    my ($self, $name, $method) = @_;  
    (!$self->has_method($name))
        || confess "Cannot add an augment method if a local method is already present";    
    my $super = $self->find_next_method_by_name($name);
    (defined $super)
        || confess "You cannot augment '$name' because it has no super method";    
    my $_super_package = $super->package_name;   
    # BUT!,... if this is an overriden method ....     
    if ($super->isa('Moose::Meta::Method::Overriden')) {
        # we need to be sure that we actually 
        # find the next method, which is not 
        # an 'override' method, the reason is
        # that an 'override' method will not 
        # be the one calling inner()
        my $real_super = $self->_find_next_method_by_name_which_is_not_overridden($name);        
        $_super_package = $real_super->package_name;
    }      
    $self->add_method($name => sub {
        my @args = @_;
        no strict   'refs';
        no warnings 'redefine';
        local *{$_super_package . '::inner'} = sub { $method->(@args) };
        return $super->(@args);
    });    
}

## Private Utility methods ...

sub _find_next_method_by_name_which_is_not_overridden {
    my ($self, $name) = @_;
    my @methods = $self->find_all_methods_by_name($name);
    foreach my $method (@methods) {
        return $method->{code} 
            if blessed($method->{code}) && !$method->{code}->isa('Moose::Meta::Method::Overriden');
    }
    return undef;
}

sub _fix_metaclass_incompatability {
    my ($self, @superclasses) = @_;
    foreach my $super (@superclasses) {
        # don't bother if it does not have a meta.
        next unless $super->can('meta');
        # if it's meta is a vanilla Moose, 
        # then we can safely ignore it.
        next if blessed($super->meta) eq 'Moose::Meta::Class';
        # but if we have anything else, 
        # we need to check it out ...
        unless (# see if of our metaclass is incompatible
                ($self->isa(blessed($super->meta)) &&
                 # and see if our instance metaclass is incompatible
                 $self->instance_metaclass->isa($super->meta->instance_metaclass)) &&
                # ... and if we are just a vanilla Moose
                $self->isa('Moose::Meta::Class')) {
            # re-initialize the meta ...
            my $super_meta = $super->meta;
            # NOTE:
            # We might want to consider actually 
            # transfering any attributes from the 
            # original meta into this one, but in 
            # general you should not have any there
            # at this point anyway, so it's very 
            # much an obscure edge case anyway
            $self = $super_meta->reinitialize($self->name => (
                ':attribute_metaclass' => $super_meta->attribute_metaclass,                            
                ':method_metaclass'    => $super_meta->method_metaclass,
                ':instance_metaclass'  => $super_meta->instance_metaclass,
            ));
        }
    }
    return $self;    
}

sub _apply_all_roles {
    my ($self, @roles) = @_;
    ($_->can('meta') && $_->meta->isa('Moose::Meta::Role'))
        || confess "You can only consume roles, $_ is not a Moose role"
            foreach @roles;
    if (scalar @roles == 1) {
        $roles[0]->meta->apply($self);
    }
    else {
        Moose::Meta::Role->combine(
            map { $_->meta } @roles
        )->apply($self);
    }    
}

sub _process_attribute {
    my ($self, $name, %options) = @_;
    if ($name =~ /^\+(.*)/) {
        my $new_attr = $self->_process_inherited_attribute($1, %options);
        $self->add_attribute($new_attr);
    }
    else {
        if ($options{metaclass}) {
            Moose::_load_all_classes($options{metaclass});
            $self->add_attribute($options{metaclass}->new($name, %options));
        }
        else {
            $self->add_attribute($name, %options);
        }
    }    
}

sub _process_inherited_attribute {
    my ($self, $attr_name, %options) = @_;
    my $inherited_attr = $self->find_attribute_by_name($attr_name);
    (defined $inherited_attr)
        || confess "Could not find an attribute by the name of '$attr_name' to inherit from";
    my $new_attr;
    if ($inherited_attr->isa('Moose::Meta::Attribute')) {
        $new_attr = $inherited_attr->clone_and_inherit_options(%options);
    }
    else {
        # NOTE:
        # kind of a kludge to handle Class::MOP::Attributes
        $new_attr = Moose::Meta::Attribute::clone_and_inherit_options(
            $inherited_attr, %options
        );                        
    }    
    return $new_attr;
}

package Moose::Meta::Method::Overriden;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Class::MOP::Method';

1;

__END__

=pod

=head1 NAME

Moose::Meta::Class - The Moose metaclass

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Class> with Moose specific 
extensions.

For the most part, the only time you will ever encounter an 
instance of this class is if you are doing some serious deep 
introspection. To really understand this class, you need to refer 
to the L<Class::MOP::Class> documentation.

=head1 METHODS

=over 4

=item B<initialize>

=item B<new_object>

We override this method to support the C<trigger> attribute option.

=item B<construct_instance>

This provides some Moose specific extensions to this method, you 
almost never call this method directly unless you really know what 
you are doing. 

This method makes sure to handle the moose weak-ref, type-constraint
and type coercion features. 

=item B<has_method ($name)>

This accomidates Moose::Meta::Role::Method instances, which are 
aliased, instead of added, but still need to be counted as valid 
methods.

=item B<add_override_method_modifier ($name, $method)>

This will create an C<override> method modifier for you, and install 
it in the package.

=item B<add_augment_method_modifier ($name, $method)>

This will create an C<augment> method modifier for you, and install 
it in the package.

=item B<calculate_all_roles>

=item B<roles>

This will return an array of C<Moose::Meta::Role> instances which are 
attached to this class.

=item B<add_role ($role)>

This takes an instance of C<Moose::Meta::Role> in C<$role>, and adds it 
to the list of associated roles.

=item B<does_role ($role_name)>

This will test if this class C<does> a given C<$role_name>. It will 
not only check it's local roles, but ask them as well in order to 
cascade down the role hierarchy.

=item B<excludes_role ($role_name)>

This will test if this class C<excludes> a given C<$role_name>. It will 
not only check it's local roles, but ask them as well in order to 
cascade down the role hierarchy.

=item B<add_attribute ($attr_name, %params|$params)>

This method does the same thing as L<Class::MOP::Class::add_attribute>, but adds
support for taking the C<$params> as a HASH ref.

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

