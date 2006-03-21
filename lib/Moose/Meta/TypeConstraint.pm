
package Moose::Meta::TypeConstraint;

use strict;
use warnings;
use metaclass;

use Sub::Name 'subname';
use Carp      'confess';

our $VERSION = '0.01';

my %TYPE_CONSTRAINT_REGISTRY;

__PACKAGE__->meta->add_attribute('name'       => (reader => 'name'      ));
__PACKAGE__->meta->add_attribute('parent'     => (reader => 'parent'    ));
__PACKAGE__->meta->add_attribute('constraint' => (reader => 'constraint'));

# private accessor
__PACKAGE__->meta->add_attribute('compiled_type_constraint' => (
    accessor => '_compiled_type_constraint'
));

__PACKAGE__->meta->add_attribute('coercion_code' => (
    reader    => 'coercion_code',
    writer    => 'set_coercion_code',        
    predicate => 'has_coercion'
));

sub new { 
    my $class  = shift;
    my $self = $class->meta->new_object(@_);
    $self->compile_type_constraint();
    return $self;
}

sub compile_type_constraint () {
    my $self   = shift;
    my $check  = $self->constraint;
    (defined $check)
        || confess "Could not compile type constraint '" . $self->name . "' because no constraint check";
    my $parent = $self->parent;
    if (defined $parent) {
        $parent = $parent->_compiled_type_constraint;
		$self->_compiled_type_constraint(subname $self->name => sub { 			
			local $_ = $_[0];
			return undef unless defined $parent->($_[0]) && $check->($_[0]);
			$_[0];
		});        
    }
    else {
    	$self->_compiled_type_constraint(subname $self->name => sub { 
    		local $_ = $_[0];
    		return undef unless $check->($_[0]);
    		$_[0];
    	});
    }
}

# backwards for now
sub constraint_code { (shift)->_compiled_type_constraint }

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint - The Moose Type Constraint metaobject

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<meta>

=item B<new>

=item B<name>

=item B<parent>

=item B<check>

=item B<constraint>

=item B<coerce>

=item B<coercion_code>

=item B<set_coercion_code>

=item B<constraint_code>

=item B<has_coercion>

=item B<compile_type_constraint>

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