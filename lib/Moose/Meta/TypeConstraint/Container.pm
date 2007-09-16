package Moose::Meta::TypeConstraint::Container;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use Carp         'confess';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('container_type' => (
    accessor  => 'container_type',
    predicate => 'has_container_type',
));

sub compile_type_constraint {
    my $self = shift;
    
    ($self->has_container_type)
        || confess "You cannot create a Container type without one";
        
    my $container_type = $self->container_type;
    
    (blessed $container_type && $container_type->isa('Moose::Meta::TypeConstraint'))
        || confess "The container type must be a Moose meta type";
    
    my $constraint;
    
    my $parent_name = $self->parent->name;
    
    if ($parent_name eq 'ArrayRef') {
        $constraint = sub {
            foreach my $x (@$_) { 
                ($container_type->check($x)) || return 
            } 1;
        };
    }
    elsif ($parent_name eq 'HashRef') {
        $constraint = sub {
            foreach my $x (values %$_) { 
                ($container_type->check($x)) || return 
            } 1;
        };          
    }
    else {
        confess "Your isa must be either ArrayRef or HashRef (sorry no subtype support yet)";
    }
    
    $self->_set_constraint($constraint);
    
    $self->SUPER::compile_type_constraint;
}

1;

__END__


=pod

=head1 NAME

Moose::Meta::TypeConstraint::Container

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<compile_type_constraint>

=item B<container_type>

=item B<has_container_type>

=item B<meta>

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
