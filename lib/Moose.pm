
package Moose;

use strict;
use warnings;

our $VERSION = '0.02';

use Scalar::Util 'blessed', 'reftype';
use Carp         'confess';
use Sub::Name    'subname';

use UNIVERSAL::require;

use Class::MOP;

use Moose::Meta::Class;
use Moose::Meta::Attribute;
use Moose::Meta::TypeConstraint;
use Moose::Meta::TypeCoercion;

use Moose::Object;
use Moose::Util::TypeConstraints;

sub import {
	shift;
	my $pkg = caller();
	
	# we should never export to main
	return if $pkg eq 'main';
	
	Moose::Util::TypeConstraints->import($pkg);
	
	# make a subtype for each Moose class
    subtype $pkg 
        => as Object 
        => where { $_->isa($pkg) };	

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
	$meta->alias_method('extends' => subname 'Moose::extends' => sub { 
	    $_->require for @_;
	    $meta->superclasses(@_) 
	});	
	
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
		    # allow for anon-subtypes here ...
		    if (blessed($options{isa}) && $options{isa}->isa('Moose::Meta::TypeConstraint')) {
				$options{type_constraint} = $options{isa};
			}
			else {
			    # otherwise assume it is a constraint
			    my $constraint = find_type_constraint($options{isa});
			    # if the constraing it not found ....
			    unless (defined $constraint) {
			        # assume it is a foreign class, and make 
			        # an anon constraint for it 
			        $constraint = subtype Object => where { $_->isa($options{isa}) };
			    }			    
                $options{type_constraint} = $constraint;
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
		$meta->add_after_method_modifier($_, $code) for @_;
	});	
	$meta->alias_method('around' => subname 'Moose::around' => sub { 
		my $code = pop @_;
		$meta->add_around_method_modifier($_, $code) for @_;	
	});	

	# make sure they inherit from Moose::Object
	$meta->superclasses('Moose::Object')
       unless $meta->superclasses();

	# we recommend using these things 
	# so export them for them
	$meta->alias_method('confess' => \&Carp::confess);			
	$meta->alias_method('blessed' => \&Scalar::Util::blessed);				
}

1;

__END__

=pod

=head1 NAME

Moose - Moose, it's the new Camel

=head1 SYNOPSIS

  package Point;
  use Moose;
  	
  has 'x' => (isa => 'Int', is => 'rw');
  has 'y' => (isa => 'Int', is => 'rw');
  
  sub clear {
      my $self = shift;
      $self->x(0);
      $self->y(0);    
  }
  
  package Point3D;
  use Moose;
  
  extends 'Point';
  
  has 'z' => (isa => 'Int');
  
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
Perl 5 objects better, but it also provides the power of metaclass 
programming.

=head2 What does Moose stand for??

Moose doesn't stand for one thing in particular, however, if you 
want, here are a few of my favorites, feel free to contribute 
more :)

=over 4

=item Make Other Object Systems Envious

=item Makes Object Orientation So Easy

=item Makes Object Orientation Spiffy- Er  (sorry ingy)

=item Most Other Object Systems Emasculate

=item My Overcraft Overfilled (with) Some Eels

=item Moose Often Ovulate Sorta Early

=item Many Overloaded Object Systems Exists 

=item Moose Offers Often Super Extensions

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item I blame Sam Vilain for giving me my first hit of meta-model crack.

=item I blame Audrey Tang for encouraging that meta-crack habit in #perl6.

=item Without the love and encouragement of Yuval "nothingmuch" Kogman, 
this module would not be possible (and it wouldn't have a name).

=item The basis of the TypeContraints module was Rob Kinyon's idea 
originally, I just ran with it.

=item Much love to mst & chansen and the whole #moose poose for all the 
ideas/feature-requests/encouragement

=back

=head1 SEE ALSO

=over 4

=item L<http://forum2.org/moose/>

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