
package Moose::Meta::Class;

use strict;
use warnings;

use Class::MOP;

use Carp         'confess';
use Scalar::Util 'weaken', 'blessed', 'reftype';

our $VERSION = '0.05';

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

sub does_role {
    my ($self, $role_name) = @_;
    (defined $role_name)
        || confess "You must supply a role name to look for";
    foreach my $role (@{$self->roles}) {
        return 1 if $role->does_role($role_name);
    }
    return 0;
}

sub new_object {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new_object(%params);
    foreach my $attr ($class->compute_all_applicable_attributes()) {
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
    my ($self, $name, %params) = @_;

    my @delegations;
    if ( my $delegation = delete $params{handles} ) {
        my @method_names_or_hashes = $self->compute_delegation( $name, $delegation, \%params );
        @delegations = $self->get_delegatable_methods( @method_names_or_hashes );
    }

    my $ret = $self->SUPER::add_attribute( $name, %params );

    if ( @delegations ) {
        my $attr = $self->get_attribute( $name );
        $self->generate_delgate_method( $attr, $_ ) for $self->filter_delegations( $attr, @delegations );
    }

    return $ret;
}

sub filter_delegations {
    my ( $self, $attr, @delegations ) = @_;
    grep {
        my $new_name = $_->{new_name} || $_->{name};
        no warnings "uninitialized";
        $_->{no_filter} or (
            !$self->name->can( $new_name ) and
            $attr->accessor ne $new_name and
            $attr->reader ne $new_name and
            $attr->writer ne $new_name
        );
    } @delegations;
}

sub generate_delgate_method {
    my ( $self, $attr, $method ) = @_;

    # FIXME like generated accessors these methods must be regenerated
    # FIXME the reader may not work for subclasses with weird instances

    my $make = $method->{generator} || sub {
        my ( $self, $attr, $method )  =@_;
    
        my $method_name = $method->{name};
        my $reader = $attr->generate_reader_method();

        return sub {
            if ( Scalar::Util::blessed( my $delegate = shift->$reader ) ) {
                return $delegate->$method_name( @_ );
            }
            return;
        };
    };

    my $new_name = $method->{new_name} || $method->{name};
    $self->add_method( $new_name, $make->( $self, $attr, $method  ) );
}

sub compute_delegation {
    my ( $self, $attr_name, $delegation, $params ) = @_;

   
    # either it's a concrete list of method names
    return $delegation unless ref $delegation; # single method name
    return @$delegation if reftype($delegation) eq "ARRAY";

    # or it's a generative api
    my $delegator_meta = $self->_guess_attr_class_or_role( $attr_name, $params );
    $self->generate_delegation_list( $delegation, $delegator_meta );
}

sub get_delegatable_methods {
    my ( $self, @names_or_hashes ) = @_;
    map { ref($_) ? $_ : { name => $_ } } @names_or_hashes;
}

sub generate_delegation_list {
    my ( $self, $delegation, $delegator_meta ) = @_;

    if ( reftype($delegation) eq "CODE" ) {
        return $delegation->( $self, $delegator_meta );
    } elsif ( blessed($delegation) eq "Regexp" ) {
        confess "For regular expression support the delegator class/role must use a Class::MOP::Class metaclass"
            unless $delegator_meta->isa( "Class::MOP::Class" );
        return grep { $_->{name} =~ /$delegation/ } $delegator_meta->compute_all_applicable_methods();
    } else {
        confess "The 'handles' specification '$delegation' is not supported";
    }
}

sub _guess_attr_class_or_role {
    my ( $self, $attr, $params ) = @_;

    my ( $isa, $does ) = @{ $params }{qw/isa does/};

    confess "Generative delegations must explicitly specify a class or a role for the attribute's type"
        unless $isa || $does;

    for (grep { blessed($_) } $isa, $does) {
        confess "You must use classes/roles, not type constraints to use delegation ($_)"
            unless $_->isa( "Moose::Meta::Class" );
    }
    
    confess "Cannot have an isa option and a does option if the isa does not do the does"
        if $isa and $does and $isa->can("does") and !$isa->does( $does );

    # if it's a class/role name make it into a meta object
    for ($isa, $does) {
        $_ = $_->meta if defined and !ref and $_->can("meta");
    }

    $isa = Class::MOP::Class->initialize($isa) if $isa and !ref($isa);

    return $isa || $does;
}

sub add_override_method_modifier {
    my ($self, $name, $method, $_super_package) = @_;
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

sub _find_next_method_by_name_which_is_not_overridden {
    my ($self, $name) = @_;
    my @methods = $self->find_all_methods_by_name($name);
    foreach my $method (@methods) {
        return $method->{code} 
            if blessed($method->{code}) && !$method->{code}->isa('Moose::Meta::Method::Overriden');
    }
    return undef;
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

=item B<add_attribute $attr_name, %params>

This method does the same thing as L<Class::MOP::Class/add_attribute>, but adds
suport for delegation.

=back

=head1 INTERNAL METHODS

=over 4

=item compute_delegation

=item generate_delegation_list

=item generate_delgate_method

=item get_delegatable_methods

=item filter_delegations

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
