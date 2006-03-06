
package Moose;

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util 'blessed';
use Carp         'confess';

use Class::MOP;
use Moose::Object;

sub import {
	shift;
	my $pkg = caller();
	
	my $meta;
	if ($pkg->can('meta')) {
		$meta = $pkg->meta();
		(blessed($meta) && $meta->isa('Class::MOP::Class'))
			|| confess "Whoops, not møøsey enough";
	}
	else {
		$meta = Class::MOP::Class->initialize($pkg);
	}

	$meta->alias_method('has' => sub {
		my ($name, %options) = @_;
		my ($init_arg) = ($name =~ /^[\$\@\%][\.\:](.*)$/);
		$meta->add_attribute($name => (
			init_arg => $init_arg,
			%options,
		));
	});

	$meta->alias_method('before' => sub { $meta->add_before_method_modifier(@_) });
	$meta->alias_method('after'  => sub { $meta->add_after_method_modifier(@_)  });	
	$meta->alias_method('around' => sub { $meta->add_around_method_modifier(@_) });	
	
	$meta->superclasses('Moose::Object') 
		unless $meta->superclasses();
}

1;

__END__

=pod

=head1 NAME

Moose - 

=head1 SYNOPSIS

  package Point;
  use Moose;
  
  has '$.x' => (reader   => 'x');
  has '$.y' => (accessor => 'y');
  
  sub clear {
      my $self = shift;
      $self->{'$.x'} = 0;
      $self->y(0);    
  }
  
  package Point3D;
  use Moose;
  
  use base 'Point';
  
  has '$:z';
  
  after 'clear' => sub {
      my $self = shift;
      $self->{'$:z'} = 0;
  };
  
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