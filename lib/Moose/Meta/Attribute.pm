
package Moose::Meta::Attribute;

use strict;
use warnings;

use Scalar::Util 'weaken', 'reftype';
use Carp         'confess';

use Moose::Util::TypeConstraints ':no_export';

our $VERSION = '0.01';

use base 'Class::MOP::Attribute';

Moose::Meta::Attribute->meta->add_attribute(
    Class::MOP::Attribute->new('weak_ref' => (
        reader    => 'weak_ref',
        predicate => {
			'has_weak_ref' => sub { $_[0]->weak_ref() ? 1 : 0 }
		}
    ))	
);

Moose::Meta::Attribute->meta->add_attribute(
    Class::MOP::Attribute->new('type_constraint' => (
        reader    => 'type_constraint',
        predicate => 'has_type_constraint',
    ))	
);

Moose::Meta::Attribute->meta->add_before_method_modifier('new' => sub {
	my (undef, undef, %options) = @_;
	(reftype($options{type_constraint}) && reftype($options{type_constraint}) eq 'CODE')
		|| confess "Type cosntraint parameter must be a code-ref, not " . $options{type_constraint}
			if exists $options{type_constraint};		
});

sub generate_accessor_method {
    my ($self, $attr_name) = @_;
	if ($self->has_type_constraint) {
		if ($self->has_weak_ref) {
		    return sub {
				if (scalar(@_) == 2) {
					(defined $self->type_constraint->($_[1]))
						|| confess "Attribute ($attr_name) does not pass the type contraint"
							if defined $_[1];
			        $_[0]->{$attr_name} = $_[1];
					weaken($_[0]->{$attr_name});
				}
		        $_[0]->{$attr_name};
		    };			
		}
		else {
		    return sub {
				if (scalar(@_) == 2) {
					(defined $self->type_constraint->($_[1]))
						|| confess "Attribute ($attr_name) does not pass the type contraint"
							if defined $_[1];
			        $_[0]->{$attr_name} = $_[1];
				}
		        $_[0]->{$attr_name};
		    };	
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
				(defined $self->type_constraint->($_[1]))
					|| confess "Attribute ($attr_name) does not pass the type contraint"
						if defined $_[1];
				$_[0]->{$attr_name} = $_[1];
				weaken($_[0]->{$attr_name});
			};
		}
		else {
		    return sub { 
				(defined $self->type_constraint->($_[1]))
					|| confess "Attribute ($attr_name) does not pass the type contraint"
						if defined $_[1];
				$_[0]->{$attr_name} = $_[1];
			};			
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