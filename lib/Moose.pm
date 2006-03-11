
use lib '/Users/stevan/CPAN/Class-MOP/Class-MOP/lib';

package Moose;

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util 'blessed';
use Carp         'confess';
use Sub::Name    'subname';

use Moose::Meta::Class;
use Moose::Meta::Attribute;

use Moose::Object;

require Moose::Util::TypeConstraints;

sub import {
	shift;
	my $pkg = caller();
	
	Moose::Util::TypeConstraints->import($pkg);
	
	my $meta;
	if ($pkg->can('meta')) {
		$meta = $pkg->meta();
		(blessed($meta) && $meta->isa('Class::MOP::Class'))
			|| confess "Whoops, not møøsey enough";
	}
	else {
		$meta = Moose::Meta::Class->initialize($pkg => (
			':attribute_metaclass' => 'Moose::Meta::Attribute'
		));		
	}
	
	# NOTE:
	# &alias_method will install the method, but it 
	# will not name it with 
	
	# handle superclasses
	$meta->alias_method('extends' => subname 'Moose::extends' => sub { $meta->superclasses(@_) });
	
	# handle attributes
	$meta->alias_method('has' => subname 'Moose::has' => sub { $meta->add_attribute(@_) });

	# handle method modifers
	$meta->alias_method('before' => subname 'Moose::before' => sub { 
		my $code = pop @_;
		$meta->add_before_method_modifier($_, $code) for @_; 
	});
	$meta->alias_method('after'  => subname 'Moose::after' => sub { 
		my $code = pop @_;
		$meta->add_after_method_modifier($_, $code)  for @_;
	});	
	$meta->alias_method('around' => subname 'Moose::around' => sub { 
		my $code = pop @_;
		$meta->add_around_method_modifier($_, $code)  for @_;	
	});	
	
	# make sure they inherit from Moose::Object
	$meta->superclasses('Moose::Object') 
		unless $meta->superclasses();

	# we recommend using these things 
	# so export them for them
	$meta->alias_method('confess' => \&confess);			
	$meta->alias_method('blessed' => \&blessed);				
}

1;

__END__

=pod

=head1 NAME

Moose - 

=head1 SYNOPSIS
  
=head1 DESCRIPTION

=head1 OTHER NAMES

Makes Other Object Systems Envious

Most Other Objects Suck Eggs

Makes Object Orientation So Easy

Metacircular Object Oriented Systems Environment

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below is the 
L<Devel::Cover> report on this module's test suite.

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut