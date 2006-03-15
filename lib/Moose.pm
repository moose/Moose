
package Moose;

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util 'blessed', 'reftype';
use Carp         'confess';
use Sub::Name    'subname';

use Moose::Meta::Class;
use Moose::Meta::Attribute;

use Moose::Object;
use Moose::Util::TypeConstraints ':no_export';

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
		$meta->add_method('meta' => sub {
			# re-initialize so it inherits properly
			Moose::Meta::Class->initialize($pkg => (
				':attribute_metaclass' => 'Moose::Meta::Attribute'
			));			
		})		
	}
	
	# NOTE:
	# &alias_method will install the method, but it 
	# will not name it with 
	
	# handle superclasses
	$meta->alias_method('extends' => subname 'Moose::extends' => sub { $meta->superclasses(@_) });
	
	# handle attributes
	$meta->alias_method('has' => subname 'Moose::has' => sub { 
		my ($name, %options) = @_;
		if (exists $options{is}) {
			if ($options{is} eq 'ro') {
				$options{reader} = $name;
			}
			elsif ($options{is} eq 'rw') {
				$options{accessor} = $name;				
			}			
		}
		if (exists $options{isa}) {
			if (reftype($options{isa}) && reftype($options{isa}) eq 'CODE') {
				$options{type_constraint} = $options{isa};
			}
			else {
				$options{type_constraint} = Moose::Util::TypeConstraints::subtype(
					Object => Moose::Util::TypeConstraints::where { $_->isa($options{isa}) }
				);			
			}
		}
		$meta->add_attribute($name, %options) 
	});

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

Moose - Moose, it's the new Camel

=head1 SYNOPSIS

  package Point;
  use Moose;
  	
  has 'x' => (isa => Int(), is => 'rw');
  has 'y' => (isa => Int(), is => 'rw');
  
  sub clear {
      my $self = shift;
      $self->x(0);
      $self->y(0);    
  }
  
  package Point3D;
  use Moose;
  
  extends 'Point';
  
  has 'z' => (isa => Int());
  
  after 'clear' => sub {
      my $self = shift;
      $self->{z} = 0;
  };
  
=head1 CAVEAT

This is a B<very> early release of this module, it still needs 
some fine tuning and B<lots> more documentation. I am adopting 
the I<release early and release often> approach with this module, 
so keep an eye on your favorite CPAN mirror!

=head1 DESCRIPTION

Moose is an extension of the Perl 5 object system. 

=head2 Another object system!?!?

Yes, I know there has been an explosion recently of new ways to 
build object's in Perl 5, most of them based on inside-out objects, 
and other such things. Moose is different because it is not a new 
object system for Perl 5, but instead an extension of the existing 
object system.

Moose is built on top of L<Class::MOP>, which is a metaclass system 
for Perl 5. This means that Moose not only makes building normal 
Perl 5 objects better, but is also provides brings with it the power 
of metaclass programming. 

=head2 What does Moose stand for??

Moose doesn't stand for one thing in particular, however, if you 
want, here are a few of my favorites, feel free to contribute 
more :)

=over 4

=item Makes Other Object Systems Envious

=item Makes Object Orientation So Easy

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