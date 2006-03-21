
package Moose::Meta::Attribute;

use strict;
use warnings;

use Scalar::Util 'weaken', 'reftype';
use Carp         'confess';

our $VERSION = '0.02';

use base 'Class::MOP::Attribute';

__PACKAGE__->meta->add_attribute('coerce'   => (reader => 'should_coerce'));
__PACKAGE__->meta->add_attribute('weak_ref' => (reader => 'is_weak_ref'  ));
__PACKAGE__->meta->add_attribute('type_constraint' => (
    reader    => 'type_constraint',
    predicate => 'has_type_constraint',
));

__PACKAGE__->meta->add_before_method_modifier('new' => sub {
	my (undef, undef, %options) = @_;
	if (exists $options{coerce} && $options{coerce}) {
	    (exists $options{type_constraint})
	        || confess "You cannot have coercion without specifying a type constraint";
        confess "You cannot have a weak reference to a coerced value"
            if $options{weak_ref};	        
	}		
});

sub generate_accessor_method {
    my ($self, $attr_name) = @_;
	if ($self->has_type_constraint) {
		if ($self->is_weak_ref) {
		    return sub {
				if (scalar(@_) == 2) {
					(defined $self->type_constraint->check($_[1]))
						|| confess "Attribute ($attr_name) does not pass the type contraint with '$_[1]'"
							if defined $_[1];
			        $_[0]->{$attr_name} = $_[1];
					weaken($_[0]->{$attr_name});
				}
		        $_[0]->{$attr_name};
		    };			
		}
		else {
		    if ($self->should_coerce) {
    		    return sub {
    				if (scalar(@_) == 2) {
    				    my $val = $self->type_constraint->coercion->coerce($_[1]);
    					(defined $self->type_constraint->check($val))
    						|| confess "Attribute ($attr_name) does not pass the type contraint with '$val'"
    							if defined $val;
    			        $_[0]->{$attr_name} = $val;
    				}
    		        $_[0]->{$attr_name};
    		    };		        
		    }
		    else {
    		    return sub {
    				if (scalar(@_) == 2) {
    					(defined $self->type_constraint->check($_[1]))
    						|| confess "Attribute ($attr_name) does not pass the type contraint with '$_[1]'"
    							if defined $_[1];
    			        $_[0]->{$attr_name} = $_[1];
    				}
    		        $_[0]->{$attr_name};
    		    };
		    }	
		}	
	}
	else {
		if ($self->is_weak_ref) {
		    return sub {
				if (scalar(@_) == 2) {
			        $_[0]->{$attr_name} = $_[1];
					weaken($_[0]->{$attr_name});
				}
		        $_[0]->{$attr_name};
		    };			
		}
		else {		
		    sub {
			    $_[0]->{$attr_name} = $_[1] if scalar(@_) == 2;
		        $_[0]->{$attr_name};
		    };		
		}
	}
}

sub generate_writer_method {
    my ($self, $attr_name) = @_; 
	if ($self->has_type_constraint) {
		if ($self->is_weak_ref) {
		    return sub { 
				(defined $self->type_constraint->check($_[1]))
					|| confess "Attribute ($attr_name) does not pass the type contraint with '$_[1]'"
						if defined $_[1];
				$_[0]->{$attr_name} = $_[1];
				weaken($_[0]->{$attr_name});
			};
		}
		else {
		    if ($self->should_coerce) {	
    		    return sub { 
    		        my $val = $self->type_constraint->coercion->coerce($_[1]);
    				(defined $self->type_constraint->check($val))
    					|| confess "Attribute ($attr_name) does not pass the type contraint with '$val'"
    						if defined $val;
    				$_[0]->{$attr_name} = $val;
    			};		        
		    }
		    else {	    
    		    return sub { 
    				(defined $self->type_constraint->check($_[1]))
    					|| confess "Attribute ($attr_name) does not pass the type contraint with '$_[1]'"
    						if defined $_[1];
    				$_[0]->{$attr_name} = $_[1];
    			};	
    		}		
		}
	}
	else {
		if ($self->is_weak_ref) {
		    return sub { 
				$_[0]->{$attr_name} = $_[1];
				weaken($_[0]->{$attr_name});
			};			
		}
		else {
		    return sub { $_[0]->{$attr_name} = $_[1] };			
		}
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

=item B<generate_accessor_method>

=item B<generate_writer_method>

=back

=head2 Additional Moose features

Moose attributes support type-contstraint checking, weak reference 
creation and type coercion.  

=over 4

=item B<has_type_constraint>

Returns true if this meta-attribute has a type constraint.

=item B<type_constraint>

A read-only accessor for this meta-attribute's type constraint. For 
more information on what you can do with this, see the documentation 
for L<Moose::Meta::TypeConstraint>.

=item B<is_weak_ref>

Returns true of this meta-attribute produces a weak reference.

=item B<should_coerce>

Returns true of this meta-attribute should perform type coercion.

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