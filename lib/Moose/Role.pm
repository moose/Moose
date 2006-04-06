
package Moose::Role;

use strict;
use warnings;

use Scalar::Util ();
use Carp         'confess';
use Sub::Name    'subname';

our $VERSION = '0.01';

use Moose::Meta::Role;

sub import {
	shift;
	my $pkg = caller();
	
	# we should never export to main
	return if $pkg eq 'main';
	
	Moose::Util::TypeConstraints->import($pkg);

	my $meta;
	if ($pkg->can('meta')) {
		$meta = $pkg->meta();
		(blessed($meta) && $meta->isa('Moose::Meta::Role'))
			|| confess "Whoops, not møøsey enough";
	}
	else {
		$meta = Moose::Meta::Role->new(
		    role_name => $pkg
		);
		$meta->role_meta->add_method('meta' => sub { $meta })		
	}
	
	# NOTE:
	# &alias_method will install the method, but it 
	# will not name it with 
	
	# handle superclasses
	$meta->role_meta->alias_method('extends' => subname 'Moose::Role::extends' => sub { 
        confess "Moose::Role does not currently support 'extends'"
	});	
	
	# handle attributes
	$meta->role_meta->alias_method('has' => subname 'Moose::Role::has' => sub { 
		my ($name, %options) = @_;
		$meta->add_attribute($name, %options) 
	});

	# handle method modifers
	$meta->role_meta->alias_method('before' => subname 'Moose::Role::before' => sub { 
		my $code = pop @_;
		$meta->add_method_modifier('before' => $_, $code) for @_;
	});
	$meta->role_meta->alias_method('after'  => subname 'Moose::Role::after' => sub { 
		my $code = pop @_;
		$meta->add_method_modifier('after' => $_, $code) for @_;
	});	
	$meta->role_meta->alias_method('around' => subname 'Moose::Role::around' => sub { 
		my $code = pop @_;
		$meta->add_method_modifier('around' => $_, $code) for @_;
	});	
	
	$meta->role_meta->alias_method('super' => subname 'Moose::Role::super' => sub {});
	$meta->role_meta->alias_method('override' => subname 'Moose::Role::override' => sub {
        my ($name, $code) = @_;
		$meta->add_method_modifier('override' => $name, $code);
	});		
	
	$meta->role_meta->alias_method('inner' => subname 'Moose::Role::inner' => sub {});
	$meta->role_meta->alias_method('augment' => subname 'Moose::Role::augment' => sub {
        my ($name, $code) = @_;
		$meta->add_method_modifier('augment' => $name, $code);
	});	

	# we recommend using these things 
	# so export them for them
	$meta->role_meta->alias_method('confess' => \&Carp::confess);			
	$meta->role_meta->alias_method('blessed' => \&Scalar::Util::blessed);    
}

1;

__END__

=pod

=head1 NAME

Moose::Role - The Moose Role

=head1 DESCRIPTION

=head1 METHODS

=over 4

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