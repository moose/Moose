
package Moose::Meta::TypeConstraint;

use strict;
use warnings;
use metaclass;

use Sub::Name    'subname';
use Carp         'confess';
use Scalar::Util 'blessed';

our $VERSION = '0.05';

__PACKAGE__->meta->add_attribute('name'       => (reader => 'name'      ));
__PACKAGE__->meta->add_attribute('parent'     => (reader => 'parent'    ));
__PACKAGE__->meta->add_attribute('constraint' => (reader => 'constraint'));
__PACKAGE__->meta->add_attribute('message'   => (
    accessor  => 'message',
    predicate => 'has_message'
));
__PACKAGE__->meta->add_attribute('coercion'   => (
    accessor  => 'coercion',
    predicate => 'has_coercion'
));

# private accessor
__PACKAGE__->meta->add_attribute('compiled_type_constraint' => (
    accessor => '_compiled_type_constraint'
));

sub new { 
    my $class = shift;
    my $self  = $class->meta->new_object(@_);
    $self->compile_type_constraint();
    return $self;
}

sub coerce { 
    ((shift)->coercion || confess "Cannot coerce without a type coercion")->coerce(@_) 
}

sub compile_type_constraint {
    my $self  = shift;
    my $check = $self->constraint;
    (defined $check)
        || confess "Could not compile type constraint '" . $self->name . "' because no constraint check";
    my $parent = $self->parent;
    if (defined $parent) {
        # we have a subtype ...
        $parent = $parent->_compiled_type_constraint;
		$self->_compiled_type_constraint(subname $self->name => sub { 			
			local $_ = $_[0];
			return undef unless defined $parent->($_[0]) && $check->($_[0]);
			1;
		});        
    }
    else {
        # we have a type ....
    	$self->_compiled_type_constraint(subname $self->name => sub { 
    		local $_ = $_[0];
    		return undef unless $check->($_[0]);
    		1;
    	});
    }
}

sub check { $_[0]->_compiled_type_constraint->($_[1]) }

sub validate { 
    my ($self, $value) = @_;
    if ($self->_compiled_type_constraint->($value)) {
        return undef;
    }
    else {
        if ($self->has_message) {
            local $_ = $value;
            return $self->message->($value);
        }
        else {
            return "Validation failed for '" . $self->name . "' failed";
        }
    }
}

sub is_a_type_of {
    my ($self, $type_name) = @_;
    ($self->name eq $type_name || $self->is_subtype_of($type_name));
}

sub is_subtype_of {
    my ($self, $type_name) = @_;
    my $current = $self;
    while (my $parent = $current->parent) {
        return 1 if $parent->name eq $type_name;
        $current = $parent;
    }
    return 0;
}

sub union {
    my ($class, @type_constraints) = @_;
    (scalar @type_constraints >= 2)
        || confess "You must pass in at least 2 Moose::Meta::TypeConstraint instances to make a union";    
    (blessed($_) && $_->isa('Moose::Meta::TypeConstraint'))
        || confess "You must pass in only Moose::Meta::TypeConstraint instances to make unions"
            foreach @type_constraints;
    return Moose::Meta::TypeConstraint::Union->new(
        type_constraints => \@type_constraints,
    );
}

package Moose::Meta::TypeConstraint::Union;

use strict;
use warnings;
use metaclass;

our $VERSION = '0.02';

__PACKAGE__->meta->add_attribute('type_constraints' => (
    accessor  => 'type_constraints',
    default   => sub { [] }
));

sub new { 
    my $class = shift;
    my $self  = $class->meta->new_object(@_);
    return $self;
}

sub name { join ' | ' => map { $_->name } @{$_[0]->type_constraints} }

# NOTE:
# this should probably never be used
# but we include it here for completeness
sub constraint    { 
    my $self = shift;
    sub { $self->check($_[0]) }; 
}

# conform to the TypeConstraint API
sub parent        { undef  }
sub message       { undef  }
sub has_message   { 0      }

# FIXME:
# not sure what this should actually do here
sub coercion { undef  }

# this should probably be memoized
sub has_coercion  {
    my $self  = shift;
    foreach my $type (@{$self->type_constraints}) {
        return 1 if $type->has_coercion
    }
    return 0;    
}

# NOTE:
# this feels too simple, and may not always DWIM
# correctly, especially in the presence of 
# close subtype relationships, however it should 
# work for a fair percentage of the use cases
sub coerce { 
    my $self  = shift;
    my $value = shift;
    foreach my $type (@{$self->type_constraints}) {
        if ($type->has_coercion) {
            my $temp = $type->coerce($value);
            return $temp if $self->check($temp);
        }
    }
    return undef;    
}

sub check {
    my $self  = shift;
    my $value = shift;
    foreach my $type (@{$self->type_constraints}) {
        return 1 if $type->check($value);
    }
    return undef;
}

sub validate {
    my $self  = shift;
    my $value = shift;
    my $message;
    foreach my $type (@{$self->type_constraints}) {
        my $err = $type->validate($value);
        return unless defined $err;
        $message .= ($message ? ' and ' : '') . $err
            if defined $err;
    }
    return ($message . ' in (' . $self->name . ')') ;    
}

sub is_a_type_of {
    my ($self, $type_name) = @_;
    foreach my $type (@{$self->type_constraints}) {
        return 1 if $type->is_a_type_of($type_name);
    }
    return 0;    
}

sub is_subtype_of {
    my ($self, $type_name) = @_;
    foreach my $type (@{$self->type_constraints}) {
        return 1 if $type->is_subtype_of($type_name);
    }
    return 0;
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint - The Moose Type Constraint metaclass

=head1 DESCRIPTION

For the most part, the only time you will ever encounter an 
instance of this class is if you are doing some serious deep 
introspection. This API should not be considered final, but 
it is B<highly unlikely> that this will matter to a regular 
Moose user.

If you wish to use features at this depth, please come to the 
#moose IRC channel on irc.perl.org and we can talk :)

=head1 METHODS

=over 4

=item B<meta>

=item B<new>

=item B<is_a_type_of ($type_name)>

This checks the current type name, and if it does not match, 
checks if it is a subtype of it.

=item B<is_subtype_of ($type_name)>

=item B<compile_type_constraint>

=item B<coerce ($value)>

This will apply the type-coercion if applicable.

=item B<check ($value)>

This method will return a true (C<1>) if the C<$value> passes the 
constraint, and false (C<0>) otherwise.

=item B<validate ($value)>

This method is similar to C<check>, but it deals with the error 
message. If the C<$value> passes the constraint, C<undef> will be 
returned. If the C<$value> does B<not> pass the constraint, then 
the C<message> will be used to construct a custom error message.  

=item B<name>

=item B<parent>

=item B<constraint>

=item B<has_message>

=item B<message>

=item B<has_coercion>

=item B<coercion>

=back

=over 4

=item B<union (@type_constraints)>

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