
package Moose::Object;

use strict;
use warnings;

use metaclass 'Moose::Meta::Class' => (
	':attribute_metaclass' => 'Moose::Meta::Attribute'
);

our $VERSION = '0.01';

sub new {
    my $class  = shift;
	my %params = @_;
	my $self = $class->meta->new_object(%params);
	$self->BUILDALL(%params);
	return $self;
}

sub BUILDALL {
	my ($self, %params) = @_;
	foreach my $method ($self->meta->find_all_methods_by_name('BUILD')) {
		$method->{method}->($self, %params);
	}
}

sub DEMOLISHALL {
	my $self = shift;
	foreach my $method ($self->meta->find_all_methods_by_name('DEMOLISH')) {
		$method->{method}->($self);
	}	
}

sub DESTROY { goto &DEMOLISHALL }

1;

__END__

=pod

=head1 NAME

Moose::Object - The base object for Moose

=head1 SYNOPSIS 

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<meta>

=item B<new>

This will create a new instance and call C<BUILDALL>.

=item B<BUILDALL>

This will call every C<BUILD> method in the inheritance hierarchy.

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