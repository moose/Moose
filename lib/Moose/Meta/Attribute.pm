
package Moose::Meta::Attribute;

use strict;
use warnings;

use Scalar::Util 'blessed', 'weaken', 'reftype';
use Carp         'confess';

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Accessor;
use Moose::Util::TypeConstraints ();

use base 'Class::MOP::Attribute';

# options which are not directly used
# but we store them for metadata purposes
__PACKAGE__->meta->add_attribute('isa'  => (reader    => '_isa_metadata'));
__PACKAGE__->meta->add_attribute('does' => (reader    => '_does_metadata'));
__PACKAGE__->meta->add_attribute('is'   => (reader    => '_is_metadata'));

# these are actual options for the attrs
__PACKAGE__->meta->add_attribute('required'   => (reader => 'is_required'      ));
__PACKAGE__->meta->add_attribute('lazy'       => (reader => 'is_lazy'          ));
__PACKAGE__->meta->add_attribute('coerce'     => (reader => 'should_coerce'    ));
__PACKAGE__->meta->add_attribute('weak_ref'   => (reader => 'is_weak_ref'      ));
__PACKAGE__->meta->add_attribute('auto_deref' => (reader => 'should_auto_deref'));
__PACKAGE__->meta->add_attribute('type_constraint' => (
    reader    => 'type_constraint',
    predicate => 'has_type_constraint',
));
__PACKAGE__->meta->add_attribute('trigger' => (
    reader    => 'trigger',
    predicate => 'has_trigger',
));
__PACKAGE__->meta->add_attribute('handles' => (
    reader    => 'handles',
    predicate => 'has_handles',
));
__PACKAGE__->meta->add_attribute('documentation' => (
    reader    => 'documentation',
    predicate => 'has_documentation',
));

sub new {
	my ($class, $name, %options) = @_;
	$class->_process_options($name, \%options);
	return $class->SUPER::new($name, %options);    
}

sub clone_and_inherit_options {
    my ($self, %options) = @_;
    # you can change default, required, coerce and documentation 
    my %actual_options;
    foreach my $legal_option (qw(default coerce required documentation)) {
        if (exists $options{$legal_option}) {
            $actual_options{$legal_option} = $options{$legal_option};
            delete $options{$legal_option};
        }
    }
    # isa can be changed, but only if the 
    # new type is a subtype    
    if ($options{isa}) {
        my $type_constraint;
	    if (blessed($options{isa}) && $options{isa}->isa('Moose::Meta::TypeConstraint')) {
			$type_constraint = $options{isa};
		}        
		else {
		    $type_constraint = Moose::Util::TypeConstraints::find_type_constraint($options{isa});
		    (defined $type_constraint)
		        || confess "Could not find the type constraint '" . $options{isa} . "'";
		}
		# NOTE:
		# check here to see if the new type 
		# is a subtype of the old one
		($type_constraint->is_subtype_of($self->type_constraint->name))
		    || confess "New type constraint setting must be a subtype of inherited one"
		        # iff we have a type constraint that is ...
		        if $self->has_type_constraint;
		# then we use it :)
		$actual_options{type_constraint} = $type_constraint;
        delete $options{isa};
    }
    (scalar keys %options == 0) 
        || confess "Illegal inherited options => (" . (join ', ' => keys %options) . ")";
    $self->clone(%actual_options);
}

sub _process_options {
    my ($class, $name, $options) = @_;
    
	if (exists $options->{is}) {
		if ($options->{is} eq 'ro') {
			$options->{reader} ||= $name;
			(!exists $options->{trigger})
			    || confess "Cannot have a trigger on a read-only attribute";
		}
		elsif ($options->{is} eq 'rw') {
			$options->{accessor} = $name;						
    	    ((reftype($options->{trigger}) || '') eq 'CODE')
    	        || confess "Trigger must be a CODE ref"
    	            if exists $options->{trigger};			
		}
		else {
		    confess "I do not understand this option (is => " . $options->{is} . ")"
		}			
	}
	
	if (exists $options->{isa}) {
	    
	    if (exists $options->{does}) {
	        if (eval { $options->{isa}->can('does') }) {
	            ($options->{isa}->does($options->{does}))	            
	                || confess "Cannot have an isa option and a does option if the isa does not do the does";
	        }
	        else {
	            confess "Cannot have an isa option which cannot ->does()";
	        }
	    }	    
	    
	    # allow for anon-subtypes here ...
	    if (blessed($options->{isa}) && $options->{isa}->isa('Moose::Meta::TypeConstraint')) {
			$options->{type_constraint} = $options->{isa};
		}
		else {
		    
		    if ($options->{isa} =~ /\|/) {
		        my @type_constraints = split /\s*\|\s*/ => $options->{isa};
		        $options->{type_constraint} = Moose::Util::TypeConstraints::create_type_constraint_union(
		            @type_constraints
		        );
		    }
		    else {
    		    # otherwise assume it is a constraint
    		    my $constraint = Moose::Util::TypeConstraints::find_type_constraint($options->{isa});	    
    		    # if the constraing it not found ....
    		    unless (defined $constraint) {
    		        # assume it is a foreign class, and make 
    		        # an anon constraint for it 
    		        $constraint = Moose::Util::TypeConstraints::subtype(
    		            'Object', 
    		            Moose::Util::TypeConstraints::where { $_->isa($options->{isa}) }
    		        );
    		    }			    
                $options->{type_constraint} = $constraint;
            }
		}
	}	
	elsif (exists $options->{does}) {	    
	    # allow for anon-subtypes here ...
	    if (blessed($options->{does}) && $options->{does}->isa('Moose::Meta::TypeConstraint')) {
			$options->{type_constraint} = $options->{isa};
		}
		else {
		    # otherwise assume it is a constraint
		    my $constraint = Moose::Util::TypeConstraints::find_type_constraint($options->{does});	      
		    # if the constraing it not found ....
		    unless (defined $constraint) {	  		        
		        # assume it is a foreign class, and make 
		        # an anon constraint for it 
		        $constraint = Moose::Util::TypeConstraints::subtype(
		            'Role', 
		            Moose::Util::TypeConstraints::where { $_->does($options->{does}) }
		        );
		    }			    
            $options->{type_constraint} = $constraint;
		}	    
	}
	
	if (exists $options->{coerce} && $options->{coerce}) {
	    (exists $options->{type_constraint})
	        || confess "You cannot have coercion without specifying a type constraint";	        
        confess "You cannot have a weak reference to a coerced value"
            if $options->{weak_ref};	        
	}	
	
	if (exists $options->{auto_deref} && $options->{auto_deref}) {
	    (exists $options->{type_constraint})
	        || confess "You cannot auto-dereference without specifying a type constraint";	    
	    ($options->{type_constraint}->is_a_type_of('ArrayRef') ||
         $options->{type_constraint}->is_a_type_of('HashRef'))
	        || confess "You cannot auto-dereference anything other than a ArrayRef or HashRef";	        
	}
	
	if (exists $options->{lazy} && $options->{lazy}) {
	    (exists $options->{default})
	        || confess "You cannot have lazy attribute without specifying a default value for it";	    
	}    
}

sub initialize_instance_slot {
    my ($self, $meta_instance, $instance, $params) = @_;
    my $init_arg = $self->init_arg();
    # try to fetch the init arg from the %params ...

    my $val;        
    if (exists $params->{$init_arg}) {
        $val = $params->{$init_arg};
    }
    else {
        # skip it if it's lazy
        return if $self->is_lazy;
        # and die if it's required and doesn't have a default value
        confess "Attribute (" . $self->name . ") is required" 
            if $self->is_required && !$self->has_default;
    }

    # if nothing was in the %params, we can use the 
    # attribute's default value (if it has one)
    if (!defined $val && $self->has_default) {
        $val = $self->default($instance); 
    }
    
	if (defined $val) {
	    if ($self->has_type_constraint) {
	        my $type_constraint = $self->type_constraint;
		    if ($self->should_coerce && $type_constraint->has_coercion) {
		        $val = $type_constraint->coerce($val);
		    }	
            (defined($type_constraint->check($val))) 
                || confess "Attribute (" . 
                           $self->name . 
                           ") does not pass the type constraint (" . 
                           $type_constraint->name .
                           ") with '$val'";			
        }
	}

    $meta_instance->set_slot_value($instance, $self->name, $val);
    $meta_instance->weaken_slot_value($instance, $self->name) 
        if ref $val && $self->is_weak_ref;
}

## Slot management

sub set_value {
    my ($self, $instance, $value) = @_;
    
    my $attr_name = $self->name;
    
    if ($self->is_required) {
        defined($value) 
            || confess "Attribute ($attr_name) is required, so cannot be set to undef";
    }
    
    if ($self->has_type_constraint) {
        
        my $type_constraint = $self->type_constraint;
        
        if ($self->should_coerce) {
            $value = $type_constraint->coerce($value);           
        }
        defined($type_constraint->_compiled_type_constraint->($value))
        	|| confess "Attribute ($attr_name) does not pass the type constraint ("
               . $type_constraint->name . ") with " . (defined($value) ? ("'" . $value . "'") : "undef")
          if defined($value);
    }
    
    my $meta_instance = Class::MOP::Class->initialize(blessed($instance))
                                         ->get_meta_instance;
                                         
    $meta_instance->set_slot_value($instance, $attr_name, $value);  
      
    if (ref $value && $self->is_weak_ref) {
        $meta_instance->weaken_slot_value($instance, $attr_name);            
    }
    
    if ($self->has_trigger) {
        $self->trigger->($instance, $value, $self);
    }
}

sub get_value {
    my ($self, $instance) = @_;
    
    if ($self->is_lazy) {
	    unless ($self->has_value($instance)) {
	        if ($self->has_default) {
	            my $default = $self->default($instance);
	            $self->set_value($instance, $default);
	        }
	        else {
                $self->set_value($instance, undef);
	        }
	    }   
    }
    
    if ($self->should_auto_deref) {
        
        my $type_constraint = $self->type_constraint;

        if ($type_constraint->is_a_type_of('ArrayRef')) {
            my $rv = $self->SUPER::get_value($instance);
            return unless defined $rv;
            return wantarray ? @{ $rv } : $rv;
        } 
        elsif ($type_constraint->is_a_type_of('HashRef')) {
            my $rv = $self->SUPER::get_value($instance);
            return unless defined $rv;
            return wantarray ? %{ $rv } : $rv;
        } 
        else {
            confess "Can not auto de-reference the type constraint '" . $type_constraint->name . "'";
        }
               
    }
    else {
        
        return $self->SUPER::get_value($instance);
    }    
}

## installing accessors 

sub accessor_metaclass { 'Moose::Meta::Method::Accessor' }

sub install_accessors {
    my $self = shift;
    $self->SUPER::install_accessors(@_);   
    
    if ($self->has_handles) {
        
        # NOTE:
        # Here we canonicalize the 'handles' option
        # this will sort out any details and always 
        # return an hash of methods which we want 
        # to delagate to, see that method for details
        my %handles = $self->_canonicalize_handles();
        
        # find the name of the accessor for this attribute
        my $accessor_name = $self->reader || $self->accessor;
        (defined $accessor_name)
            || confess "You cannot install delegation without a reader or accessor for the attribute";
        
        # make sure we handle HASH accessors correctly
        ($accessor_name) = keys %{$accessor_name}
            if ref($accessor_name) eq 'HASH';
        
        # install the delegation ...
        my $associated_class = $self->associated_class;
        foreach my $handle (keys %handles) {
            my $method_to_call = $handles{$handle};
            
            (!$associated_class->has_method($handle))
                || confess "You cannot overwrite a locally defined method ($handle) with a delegation";
            
            # NOTE:
            # handles is not allowed to delegate
            # any of these methods, as they will 
            # override the ones in your class, which 
            # is almost certainly not what you want.
            next if $handle =~ /^BUILD|DEMOLISH$/ || Moose::Object->can($handle);
            
            if ((reftype($method_to_call) || '') eq 'CODE') {
                $associated_class->add_method($handle => $method_to_call);                
            }
            else {
                $associated_class->add_method($handle => sub {
                    # FIXME
                    # we should check for lack of 
                    # a callable return value from 
                    # the accessor here 
                    my $proxy = (shift)->$accessor_name();
                    @_ = ($proxy, @_);
                    goto &{ $proxy->can($method_to_call)};
                });
            }
        }
    }
    
    return;
}

# private methods to help delegation ...

sub _canonicalize_handles {
    my $self    = shift;
    my $handles = $self->handles;
    if (ref($handles) eq 'HASH') {
        return %{$handles};
    }
    elsif (ref($handles) eq 'ARRAY') {
        return map { $_ => $_ } @{$handles};
    }
    elsif (ref($handles) eq 'Regexp') {
        ($self->has_type_constraint)
            || confess "Cannot delegate methods based on a RegExpr without a type constraint (isa)";
        return map  { ($_ => $_) } 
               grep { /$handles/ } $self->_get_delegate_method_list;
    }
    elsif (ref($handles) eq 'CODE') {
        return $handles->($self, $self->_find_delegate_metaclass);
    }
    else {
        confess "Unable to canonicalize the 'handles' option with $handles";
    }
}

sub _find_delegate_metaclass {
    my $self = shift;
    if (my $class = $self->_isa_metadata) {
        # if the class does have 
        # a meta method, use it
        return $class->meta if $class->can('meta');
        # otherwise we might be 
        # dealing with a non-Moose
        # class, and need to make 
        # our own metaclass
        return Moose::Meta::Class->initialize($class);
    }
    elsif (my $role = $self->_does_metadata) {
        # our role will always have 
        # a meta method
        return $role->meta;
    }
    else {
        confess "Cannot find delegate metaclass for attribute " . $self->name;
    }
}

sub _get_delegate_method_list {
    my $self = shift;
    my $meta = $self->_find_delegate_metaclass;
    if ($meta->isa('Class::MOP::Class')) {
        return map  { $_->{name}                     }  # NOTE: !never! delegate &meta
               grep { $_->{class} ne 'Moose::Object' && $_->{name} ne 'meta' } 
                    $meta->compute_all_applicable_methods;
    }
    elsif ($meta->isa('Moose::Meta::Role')) {
        return $meta->get_method_list;        
    }
    else {
        confess "Unable to recognize the delegate metaclass '$meta'";
    }
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute - The Moose attribute metaclass

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Attribute> with Moose specific 
extensions. 

For the most part, the only time you will ever encounter an 
instance of this class is if you are doing some serious deep 
introspection. To really understand this class, you need to refer 
to the L<Class::MOP::Attribute> documentation.

=head1 METHODS

=head2 Overridden methods

These methods override methods in L<Class::MOP::Attribute> and add 
Moose specific features. You can safely assume though that they 
will behave just as L<Class::MOP::Attribute> does.

=over 4

=item B<new>

=item B<initialize_instance_slot>

=item B<install_accessors>

=item B<accessor_metaclass>

=item B<get_value>

=item B<set_value>

=back

=head2 Additional Moose features

Moose attributes support type-constraint checking, weak reference 
creation and type coercion.  

=over 4

=item B<clone_and_inherit_options>

This is to support the C<has '+foo'> feature, it clones an attribute 
from a superclass and allows a very specific set of changes to be made 
to the attribute.

=item B<has_type_constraint>

Returns true if this meta-attribute has a type constraint.

=item B<type_constraint>

A read-only accessor for this meta-attribute's type constraint. For 
more information on what you can do with this, see the documentation 
for L<Moose::Meta::TypeConstraint>.

=item B<has_handles>

Returns true if this meta-attribute performs delegation.

=item B<handles>

This returns the value which was passed into the handles option.

=item B<is_weak_ref>

Returns true if this meta-attribute produces a weak reference.

=item B<is_required>

Returns true if this meta-attribute is required to have a value.

=item B<is_lazy>

Returns true if this meta-attribute should be initialized lazily.

NOTE: lazy attributes, B<must> have a C<default> field set.

=item B<should_coerce>

Returns true if this meta-attribute should perform type coercion.

=item B<should_auto_deref>

Returns true if this meta-attribute should perform automatic 
auto-dereferencing. 

NOTE: This can only be done for attributes whose type constraint is 
either I<ArrayRef> or I<HashRef>.

=item B<has_trigger>

Returns true if this meta-attribute has a trigger set.

=item B<trigger>

This is a CODE reference which will be executed every time the 
value of an attribute is assigned. The CODE ref will get two values, 
the invocant and the new value. This can be used to handle I<basic> 
bi-directional relations.

=item B<documentation>

This is a string which contains the documentation for this attribute. 
It serves no direct purpose right now, but it might in the future
in some kind of automated documentation system perhaps.

=item B<has_documentation>

Returns true if this meta-attribute has any documentation.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
