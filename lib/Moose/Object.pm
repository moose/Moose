
package Moose::Object;

use strict;
use warnings;
use metaclass 'Moose::Meta::Class' => (
	':attribute_metaclass' => 'Moose::Meta::Attribute'
);

our $VERSION = '0.02';

sub new {
	my ($class, %params) = @_;
	my $self = $class->meta->new_object(%params);
	$self->BUILDALL(\%params);
	return $self;
}

sub BUILDALL {
	my ($self, $params) = @_;
	foreach my $method (reverse $self->meta->find_all_methods_by_name('BUILD')) {
		$method->{code}->($self, $params);
	}
}

sub DEMOLISHALL {
	my $self = shift;
	foreach my $method ($self->meta->find_all_methods_by_name('DEMOLISH')) {
		$method->{code}->($self);
	}	
}

sub DESTROY { goto &DEMOLISHALL }

1;

__END__

=pod

=head1 NAME

Moose::Object - The base object for Moose

=head1 DESCRIPTION

This serves as the base object for all Moose classes. Every 
effort will be made to ensure that all classes which C<use Moose> 
will inherit from this class. It provides a default constructor 
and destructor, which run all the BUILD and DEMOLISH methods in 
the class tree.

You don't actually I<need> to inherit from this in order to 
use Moose though. It is just here to make life easier.

=head1 METHODS

=over 4

=item B<meta>

This will return the metaclass associated with the given class.

=item B<new>

This will create a new instance and call C<BUILDALL>.

=item B<BUILDALL>

This will call every C<BUILD> method in the inheritance hierarchy, 
and pass it a hash-ref of the the C<%params> passed to C<new>.

=item B<DEMOLISHALL>

This will call every C<DEMOLISH> method in the inheritance hierarchy.

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