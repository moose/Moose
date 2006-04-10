
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
		$meta = Moose::Meta::Role->new(role_name => $pkg);
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
	
	$meta->role_meta->alias_method('inner' => subname 'Moose::Role::inner' => sub {
        confess "Moose::Role does not currently support 'inner'";	    
	});
	$meta->role_meta->alias_method('augment' => subname 'Moose::Role::augment' => sub {
        confess "Moose::Role does not currently support 'augment'";
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

=head1 SYNOPSIS

  package Eq;
  use strict;
  use warnings;
  use Moose::Role;
  
  sub equal { confess "equal must be implemented" }
  
  sub no_equal { 
      my ($self, $other) = @_;
      !$self->equal($other);
  }
  
  # ... then in your classes
  
  package Currency;
  use strict;
  use warnings;
  use Moose;
  
  with 'Eq';
  
  sub equal {
      my ($self, $other) = @_;
      $other->as_float == $other->as_float;
  }

=head1 DESCRIPTION

This is currently a very early release of Perl 6 style Roles for 
Moose, it should be considered experimental and incomplete.

This feature is being actively developed, but $work is currently 
preventing me from paying as much attention to it as I would like. 
So I am releasing it in hopes people will help me on this I<hint hint>.

If you are interested in helping, please come to #moose on irc.perl.org
and we can talk. 

=head1 CAVEATS

Currently, the role support has a number of caveats. They are as follows:

=over 4

=item *

There is no support for Roles consuming other Roles. The details of this 
are not totally worked out yet, but it will mostly follow what is set out 
in the Perl 6 Synopsis 12.

=item *

At this time classes I<can> consume more than one Role, but they are simply 
applied one after another in the order you ask for them. This is incorrect 
behavior, the roles should be merged first, and conflicts determined, etc. 
However, if your roles do not have any conflicts, then things will work just 
fine.

=item * 

I want to have B<required> methods, which is unlike Perl 6 roles, and more 
like the original Traits on which roles are based. This would be similar 
in behavior to L<Class::Trait>. These are not yet implemented or course.

=item *

Roles cannot use the C<extends> keyword, it will throw an exception for now. 
The same is true of the C<augment> and C<inner> keywords (not sure those 
really make sense for roles). All other Moose keywords will be I<deferred> 
so that they can be applied to the consuming class. 

=back

Basically thats all I can think of for now, I am sure there are more though.

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