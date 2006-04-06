
package Moose::Meta::Attribute;

use strict;
use warnings;

use Scalar::Util 'blessed', 'weaken', 'reftype';
use Carp         'confess';

our $VERSION = '0.03';

use Moose::Util::TypeConstraints '-no-export';

use base 'Class::MOP::Attribute';

__PACKAGE__->meta->add_attribute('required' => (reader => 'is_required'  ));
__PACKAGE__->meta->add_attribute('lazy'     => (reader => 'is_lazy'      ));
__PACKAGE__->meta->add_attribute('coerce'   => (reader => 'should_coerce'));
__PACKAGE__->meta->add_attribute('weak_ref' => (reader => 'is_weak_ref'  ));
__PACKAGE__->meta->add_attribute('type_constraint' => (
    reader    => 'type_constraint',
    predicate => 'has_type_constraint',
));

sub new {
	my ($class, $name, %options) = @_;
	
	if (exists $options{is}) {
		if ($options{is} eq 'ro') {
			$options{reader} = $name;
		}
		elsif ($options{is} eq 'rw') {
			$options{accessor} = $name;				
		}			
	}
	
	if (exists $options{isa}) {
	    # allow for anon-subtypes here ...
	    if (blessed($options{isa}) && $options{isa}->isa('Moose::Meta::TypeConstraint')) {
			$options{type_constraint} = $options{isa};
		}
		else {
		    # otherwise assume it is a constraint
		    my $constraint = Moose::Util::TypeConstraints::find_type_constraint($options{isa});
		    # if the constraing it not found ....
		    unless (defined $constraint) {
		        # assume it is a foreign class, and make 
		        # an anon constraint for it 
		        $constraint = Moose::Util::TypeConstraints::subtype(
		            'Object', 
		            Moose::Util::TypeConstraints::where { $_->isa($options{isa}) }
		        );
		    }			    
            $options{type_constraint} = $constraint;
		}
	}	
	
	if (exists $options{coerce} && $options{coerce}) {
	    (exists $options{type_constraint})
	        || confess "You cannot have coercion without specifying a type constraint";
        confess "You cannot have a weak reference to a coerced value"
            if $options{weak_ref};	        
	}	
	
	if (exists $options{lazy} && $options{lazy}) {
	    (exists $options{default})
	        || confess "You cannot have lazy attribute without specifying a default value for it";	    
	}
	
	$class->SUPER::new($name, %options);	
}

sub generate_accessor_method {
    my ($self, $attr_name) = @_;
    my $value_name = $self->should_coerce ? '$val' : '$_[1]';
    my $code = 'sub { '
    . 'if (scalar(@_) == 2) {'
        . ($self->is_required ? 
            'defined($_[1]) || confess "Attribute ($attr_name) is required, so cannot be set to undef";' 
            : '')
        . ($self->should_coerce ? 
            'my $val = $self->type_constraint->coercion->coerce($_[1]);'
            : '')
        . ($self->has_type_constraint ? 
            ('(defined $self->type_constraint->check(' . $value_name . '))'
            	. '|| confess "Attribute ($attr_name) does not pass the type contraint with \'' . $value_name . '\'"'
            		. 'if defined ' . $value_name . ';')
            : '')
        . '$_[0]->{$attr_name} = ' . $value_name . ';'
        . ($self->is_weak_ref ?
            'weaken($_[0]->{$attr_name});'
            : '')
    . ' }'
    . ($self->is_lazy ? 
            '$_[0]->{$attr_name} = ($self->has_default ? $self->default($_[0]) : undef)'
            . 'unless exists $_[0]->{$attr_name};'
            : '')    
    . ' $_[0]->{$attr_name};'
    . ' }';
    my $sub = eval $code;
    confess "Could not create writer for '$attr_name' because $@ \n code: $code" if $@;
    return $sub;    
}

sub generate_writer_method {
    my ($self, $attr_name) = @_; 
    my $value_name = $self->should_coerce ? '$val' : '$_[1]';
    my $code = 'sub { '
    . ($self->is_required ? 
        'defined($_[1]) || confess "Attribute ($attr_name) is required, so cannot be set to undef";' 
        : '')
    . ($self->should_coerce ? 
        'my $val = $self->type_constraint->coercion->coerce($_[1]);'
        : '')
    . ($self->has_type_constraint ? 
        ('(defined $self->type_constraint->check(' . $value_name . '))'
        	. '|| confess "Attribute ($attr_name) does not pass the type contraint with \'' . $value_name . '\'"'
        		. 'if defined ' . $value_name . ';')
        : '')
    . '$_[0]->{$attr_name} = ' . $value_name . ';'
    . ($self->is_weak_ref ?
        'weaken($_[0]->{$attr_name});'
        : '')
    . ' }';
    my $sub = eval $code;
    confess "Could not create writer for '$attr_name' because $@ \n code: $code" if $@;
    return $sub;    
}

sub generate_reader_method {
    my ($self, $attr_name) = @_; 
    my $code = 'sub {'
    . 'confess "Cannot assign a value to a read-only accessor" if @_ > 1;'
    . ($self->is_lazy ? 
            '$_[0]->{$attr_name} = ($self->has_default ? $self->default($_[0]) : undef)'
            . 'unless exists $_[0]->{$attr_name};'
            : '')
    . '$_[0]->{$attr_name};'
    . '}';
    my $sub = eval $code;
    confess "Could not create reader for '$attr_name' because $@ \n code: $code" if $@;
    return $sub;
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

=item B<generate_reader_method>

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

=item B<is_required>

Returns true of this meta-attribute is required to have a value.

=item B<is_lazy>

Returns true of this meta-attribute should be initialized lazily.

NOTE: lazy attributes, B<must> have a C<default> field set.

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