
package Moose::Meta::Attribute;

use strict;
use warnings;

use Scalar::Util 'weaken', 'reftype';
use Carp         'confess';

our $VERSION = '0.02';

use base 'Class::MOP::Attribute';

__PACKAGE__->meta->add_attribute('coerce' => (
    reader    => 'coerce',
    predicate => { 'has_coercion' => sub { $_[0]->coerce() ? 1 : 0 } }
));

__PACKAGE__->meta->add_attribute('weak_ref' => (
    reader    => 'weak_ref',
    predicate => { 'has_weak_ref' => sub { $_[0]->weak_ref() ? 1 : 0 } }
));

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
		if ($self->has_weak_ref) {
		    return sub {
				if (scalar(@_) == 2) {
					(defined $self->type_constraint->constraint_code->($_[1]))
						|| confess "Attribute ($attr_name) does not pass the type contraint with '$_[1]'"
							if defined $_[1];
			        $_[0]->{$attr_name} = $_[1];
					weaken($_[0]->{$attr_name});
				}
		        $_[0]->{$attr_name};
		    };			
		}
		else {
		    if ($self->has_coercion) {
    		    return sub {
    				if (scalar(@_) == 2) {
    				    my $val = $self->type_constraint->coercion_code->($_[1]);
    					(defined $self->type_constraint->constraint_code->($val))
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
    					(defined $self->type_constraint->constraint_code->($_[1]))
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
		if ($self->has_weak_ref) {
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
		if ($self->has_weak_ref) {
		    return sub { 
				(defined $self->type_constraint->constraint_code->($_[1]))
					|| confess "Attribute ($attr_name) does not pass the type contraint with '$_[1]'"
						if defined $_[1];
				$_[0]->{$attr_name} = $_[1];
				weaken($_[0]->{$attr_name});
			};
		}
		else {
		    if ($self->has_coercion) {	
    		    return sub { 
    		        my $val = $self->type_constraint->coercion_code->($_[1]);
    				(defined $self->type_constraint->constraint_code->($val))
    					|| confess "Attribute ($attr_name) does not pass the type contraint with '$val'"
    						if defined $val;
    				$_[0]->{$attr_name} = $val;
    			};		        
		    }
		    else {	    
    		    return sub { 
    				(defined $self->type_constraint->constraint_code->($_[1]))
    					|| confess "Attribute ($attr_name) does not pass the type contraint with '$_[1]'"
    						if defined $_[1];
    				$_[0]->{$attr_name} = $_[1];
    			};	
    		}		
		}
	}
	else {
		if ($self->has_weak_ref) {
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

Moose::Meta::Attribute - The Moose attribute metaobject

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Attribute> with Moose specific 
extensions.

=head1 METHODS

=over 4

=item B<new>

=item B<generate_accessor_method>

=item B<generate_writer_method>

=back

=over 4

=item B<has_type_constraint>

=item B<type_constraint>

=item B<has_weak_ref>

=item B<weak_ref>

=item B<coerce>

=item B<has_coercion>

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