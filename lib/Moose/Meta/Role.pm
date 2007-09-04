
package Moose::Meta::Role;

use strict;
use warnings;
use metaclass;

use Carp         'confess';
use Scalar::Util 'blessed';
use B            'svref_2object';

our $VERSION   = '0.09';
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Class;
use Moose::Meta::Role::Method;
use Moose::Meta::Role::Method::Required;

use base 'Class::MOP::Module';


# NOTE:
# I normally don't do this, but I am doing 
# a whole bunch of meta-programmin in this 
# module, so it just makes sense.
# - SL 

my $META = __PACKAGE__->meta;

## ------------------------------------------------------------------
## attributes ...

# NOTE:
# since roles are lazy, we hold all the attributes
# of the individual role in 'statis' until which 
# time when it is applied to a class. This means 
# keeping a lot of things in hash maps, so we are 
# using a little of that meta-programmin' magic
# here an saving lots of extra typin.
# - SL

$META->add_attribute($_->{name} => (
    reader  => $_->{reader},
    default => sub { {} }
)) for (
    { name => 'excluded_roles_map', reader => 'get_excluded_roles_map'   },
    { name => 'attribute_map',      reader => 'get_attribute_map'        },
    { name => 'required_methods',   reader => 'get_required_methods_map' },
);

# NOTE:
# many of these attributes above require similar 
# functionality to support them, so we again use 
# the wonders of meta-programmin' to deliver a 
# very compact solution to this normally verbose
# problem.
# - SL

foreach my $action (
    { 
        attr_reader => 'get_excluded_roles_map' ,   
        methods     => {
            add       => 'add_excluded_roles',    
            get_list  => 'get_excluded_roles_list',  
            existence => 'excludes_role',         
        }
    },
    { 
        attr_reader => 'get_required_methods_map',
        methods     => {
            add       => 'add_required_methods', 
            remove    => 'remove_required_methods',
            get_list  => 'get_required_method_list',
            existence => 'requires_method',
        }
    },
    {
        attr_reader => 'get_attribute_map',
        methods     => {
            get       => 'get_attribute',
            get_list  => 'get_attribute_list',
            existence => 'has_attribute',
            remove    => 'remove_attribute',
        }
    }
) {
    
    my $attr_reader = $action->{attr_reader};
    my $methods     = $action->{methods};
    
    $META->add_method($methods->{add} => sub {
        my ($self, @values) = @_;
        $self->$attr_reader->{$_} = undef foreach @values;    
    }) if exists $methods->{add};
    
    $META->add_method($methods->{get_list} => sub {
        my ($self) = @_;
        keys %{$self->$attr_reader};   
    }) if exists $methods->{get_list}; 
    
    $META->add_method($methods->{get} => sub {
        my ($self, $name) = @_;
        $self->$attr_reader->{$name}  
    }) if exists $methods->{get};    
    
    $META->add_method($methods->{existence} => sub {
        my ($self, $name) = @_;
        exists $self->$attr_reader->{$name} ? 1 : 0;   
    }) if exists $methods->{existence};    
    
    $META->add_method($methods->{remove} => sub {
        my ($self, @values) = @_;
        delete $self->$attr_reader->{$_} foreach @values;
    }) if exists $methods->{remove};       
}

## some things don't always fit, so they go here ...

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

sub _clean_up_required_methods {
    my $self = shift;
    foreach my $method ($self->get_required_method_list) {
        $self->remove_required_methods($method)
            if $self->has_method($method);
    } 
}

## ------------------------------------------------------------------
## method modifiers

$META->add_attribute($_->{name} => (
    reader  => $_->{reader},
    default => sub { {} }
)) for (
    { name => 'before_method_modifiers',   reader => 'get_before_method_modifiers_map'   },
    { name => 'after_method_modifiers',    reader => 'get_after_method_modifiers_map'    },
    { name => 'around_method_modifiers',   reader => 'get_around_method_modifiers_map'   },
    { name => 'override_method_modifiers', reader => 'get_override_method_modifiers_map' },
);

# NOTE:
# the before/around/after method modifiers are 
# stored by name, but there can be many methods
# then associated with that name. So again we have
# lots of similar functionality, so we can do some
# meta-programmin' and save some time.
# - SL

foreach my $modifier_type (qw[ before around after ]) {
    
    my $attr_reader = "get_${modifier_type}_method_modifiers_map";    
    
    $META->add_method("get_${modifier_type}_method_modifiers" => sub {
        my ($self, $method_name) = @_;
        @{$self->$attr_reader->{$method_name}};
    });
        
    $META->add_method("has_${modifier_type}_method_modifiers" => sub {
        my ($self, $method_name) = @_;
        # NOTE:
        # for now we assume that if it exists,.. 
        # it has at least one modifier in it
        (exists $self->$attr_reader->{$method_name}) ? 1 : 0;
    });    
    
    $META->add_method("add_${modifier_type}_method_modifier" => sub {
        my ($self, $method_name, $method) = @_;
        
        $self->$attr_reader->{$method_name} = [] 
            unless exists $self->$attr_reader->{$method_name};
            
        my $modifiers = $self->$attr_reader->{$method_name};
        
        # NOTE:
        # check to see that we aren't adding the 
        # same code twice. We err in favor of the 
        # first on here, this may not be as expected
        foreach my $modifier (@{$modifiers}) {
            return if $modifier == $method;
        }
        
        push @{$modifiers} => $method;
    });
    
}

## ------------------------------------------------------------------
## override method mofidiers

# NOTE:
# these are a little different because there 
# can only be one per name, whereas the other
# method modifiers can have multiples.
# - SL

sub add_override_method_modifier {
    my ($self, $method_name, $method) = @_;
    (!$self->has_method($method_name))
        || confess "Cannot add an override of method '$method_name' " . 
                   "because there is a local version of '$method_name'";
    $self->get_override_method_modifiers_map->{$method_name} = $method;    
}

sub has_override_method_modifier {
    my ($self, $method_name) = @_;
    # NOTE:
    # for now we assume that if it exists,.. 
    # it has at least one modifier in it
    (exists $self->get_override_method_modifiers_map->{$method_name}) ? 1 : 0;    
}

sub get_override_method_modifier {
    my ($self, $method_name) = @_;
    $self->get_override_method_modifiers_map->{$method_name};    
}

## general list accessor ...

sub get_method_modifier_list {
    my ($self, $modifier_type) = @_;
    my $accessor = "get_${modifier_type}_method_modifiers_map";    
    keys %{$self->$accessor};
}

## ------------------------------------------------------------------
## subroles

__PACKAGE__->meta->add_attribute('roles' => (
    reader  => 'get_roles',
    default => sub { [] }
));

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || confess "Roles must be instances of Moose::Meta::Role";
    push @{$self->get_roles} => $role;
}

sub calculate_all_roles {
    my $self = shift;
    my %seen;
    grep { 
        !$seen{$_->name}++ 
    } ($self, 
       map { 
           $_->calculate_all_roles 
       } @{ $self->get_roles });
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

## ------------------------------------------------------------------
## methods 

sub method_metaclass { 'Moose::Meta::Role::Method' }

# FIXME:
# this is an UGLY hack
sub get_method_map {    
    my $self = shift;
    $self->{'%!methods'} ||= {}; 
    $self->Moose::Meta::Class::get_method_map() 
}

# FIXME:
# Yes, this is a really really UGLY hack
# but it works, and until I can figure 
# out a better way, this is gonna be it. 

sub get_method          { (shift)->Moose::Meta::Class::get_method(@_)          }
sub has_method          { (shift)->Moose::Meta::Class::has_method(@_)          }
sub alias_method        { (shift)->Moose::Meta::Class::alias_method(@_)        }
sub get_method_list     { 
    grep {
        !/^meta$/
    } (shift)->Moose::Meta::Class::get_method_list(@_)     
}

sub find_method_by_name { (shift)->get_method(@_) }

## ------------------------------------------------------------------
## role construction 
## ------------------------------------------------------------------

my $anon_counter = 0;

sub apply {
    my ($self, $other) = @_;
    
    unless ($other->isa('Moose::Meta::Class') || $other->isa('Moose::Meta::Role')) {
    
        # Runtime Role mixins
            
        # FIXME:
        # We really should do this better, and 
        # cache the results of our efforts so 
        # that we don't need to repeat them.
        
        my $pkg_name = __PACKAGE__ . "::__RUNTIME_ROLE_ANON_CLASS__::" . $anon_counter++;
        eval "package " . $pkg_name . "; our \$VERSION = '0.00';";
        die $@ if $@;

        my $object = $other;

        $other = Moose::Meta::Class->initialize($pkg_name);
        $other->superclasses(blessed($object));     
        
        bless $object => $pkg_name;
    }
    
    $self->_check_excluded_roles($other);
    $self->_check_required_methods($other);  

    $self->_apply_attributes($other);         
    $self->_apply_methods($other);   

    $self->_apply_override_method_modifiers($other);                  
    $self->_apply_before_method_modifiers($other);                  
    $self->_apply_around_method_modifiers($other);                  
    $self->_apply_after_method_modifiers($other);          

    $other->add_role($self);
}

sub combine {
    my ($class, @roles) = @_;
    
    my $pkg_name = __PACKAGE__ . "::__COMPOSITE_ROLE_SANDBOX__::" . $anon_counter++;
    eval "package " . $pkg_name . "; our \$VERSION = '0.00';";
    die $@ if $@;
    
    my $combined = $class->initialize($pkg_name);
    
    foreach my $role (@roles) {
        $role->apply($combined);
    }
    
    $combined->_clean_up_required_methods;   
    
    return $combined;
}

## ------------------------------------------------------------------

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
        else {
            # NOTE:
            # we need to make sure that the method is 
            # not a method modifier, because those do 
            # not satisfy the requirements ...
            my $method = $other->find_method_by_name($required_method_name);
            # check if it is an override or a generated accessor ..
            (!$method->isa('Moose::Meta::Method::Overriden') &&
             !$method->isa('Class::MOP::Method::Accessor'))
                || confess "'" . $self->name . "' requires the method '$required_method_name' " . 
                           "to be implemented by '" . $other->name . "', the method is only a method modifier";
            # before/after/around methods are a little trickier
            # since we wrap the original local method (if applicable)
            # so we need to check if the original wrapped method is 
            # from the same package, and not a wrap of the super method 
            if ($method->isa('Class::MOP::Method::Wrapped')) {
                ($method->get_original_method->package_name eq $other->name)
                    || confess "'" . $self->name . "' requires the method '$required_method_name' " . 
                               "to be implemented by '" . $other->name . "', the method is only a method modifier";            
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
            # NOTE:
            # this is kinda ugly ...
            if ($other->isa('Moose::Meta::Class')) { 
                $other->_process_attribute(
                    $attribute_name,
                    %{$self->get_attribute($attribute_name)}
                );             
            }
            else {
                $other->add_attribute(
                    $attribute_name,
                    $self->get_attribute($attribute_name)
                );                
            }
        }
    }    
}

sub _apply_methods {
    my ($self, $other) = @_;   
    foreach my $method_name ($self->get_method_list) {
        # it if it has one already
        if ($other->has_method($method_name) &&
            # and if they are not the same thing ...
            $other->get_method($method_name)->body != $self->get_method($method_name)->body) {
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
                $other->Moose::Meta::Class::remove_method($method_name)
                    if $other->name =~ /__COMPOSITE_ROLE_SANDBOX__/;
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

sub _apply_override_method_modifiers {
    my ($self, $other) = @_;    
    foreach my $method_name ($self->get_method_modifier_list('override')) {
        # it if it has one already then ...
        if ($other->has_method($method_name)) {
            # if it is being composed into another role
            # we have a conflict here, because you cannot 
            # combine an overriden method with a locally
            # defined one 
            if ($other->isa('Moose::Meta::Role')) { 
                confess "Role '" . $self->name . "' has encountered an 'override' method conflict " . 
                        "during composition (A local method of the same name as been found). This " . 
                        "is fatal error.";
            }
            else {
                # if it is a class, then we 
                # just ignore this here ...
                next;
            }
        }
        else {
            # if no local method is found, then we 
            # must check if we are a role or class
            if ($other->isa('Moose::Meta::Role')) { 
                # if we are a role, we need to make sure 
                # we dont have a conflict with the role 
                # we are composing into
                if ($other->has_override_method_modifier($method_name) &&
                    $other->get_override_method_modifier($method_name) != $self->get_override_method_modifier($method_name)) {
                    confess "Role '" . $self->name . "' has encountered an 'override' method conflict " . 
                            "during composition (Two 'override' methods of the same name encountered). " . 
                            "This is fatal error.";
                }
                else {   
                    # if there is no conflict,
                    # just add it to the role  
                    $other->add_override_method_modifier(
                        $method_name, 
                        $self->get_override_method_modifier($method_name)
                    );                    
                }
            }
            else {
                # if this is not a role, then we need to 
                # find the original package of the method
                # so that we can tell the class were to 
                # find the right super() method
                my $method = $self->get_override_method_modifier($method_name);
                my $package = svref_2object($method)->GV->STASH->NAME;
                # if it is a class, we just add it
                $other->add_override_method_modifier($method_name, $method, $package);
            }
        }
    }    
}

sub _apply_method_modifiers {
    my ($self, $modifier_type, $other) = @_;    
    my $add = "add_${modifier_type}_method_modifier";
    my $get = "get_${modifier_type}_method_modifiers";    
    foreach my $method_name ($self->get_method_modifier_list($modifier_type)) {
        $other->$add(
            $method_name,
            $_
        ) foreach $self->$get($method_name);
    }    
}

sub _apply_before_method_modifiers { (shift)->_apply_method_modifiers('before' => @_) }
sub _apply_around_method_modifiers { (shift)->_apply_method_modifiers('around' => @_) }
sub _apply_after_method_modifiers  { (shift)->_apply_method_modifiers('after'  => @_) }

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role - The Moose Role metaclass

=head1 DESCRIPTION

Please see L<Moose::Role> for more information about roles. 
For the most part, this has no user-serviceable parts inside
this module. It's API is still subject to some change (although 
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

=item B<method_metaclass>

=item B<find_method_by_name>

=item B<get_method>

=item B<has_method>

=item B<alias_method>

=item B<get_method_list>

=item B<get_method_map>

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

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
