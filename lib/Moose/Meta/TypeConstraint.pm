
package Moose::Meta::TypeConstraint;

use strict;
use warnings;
use metaclass;

use Sub::Name 'subname';
use Carp      'confess';

our $VERSION = '0.02';

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

sub compile_type_constraint () {
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
			$_[0];
		});        
    }
    else {
        # we have a type ....
    	$self->_compiled_type_constraint(subname $self->name => sub { 
    		local $_ = $_[0];
    		return undef unless $check->($_[0]);
    		$_[0];
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
            return "Validation failed for '" . $self->name . "' failed.";
        }
    }
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

=item B<compile_type_constraint>

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