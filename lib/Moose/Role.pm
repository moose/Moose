
package Moose::Role;

use strict;
use warnings;

use Scalar::Util ();
use Carp         'confess';
use Sub::Name    'subname';

our $VERSION = '0.02';

use Moose::Meta::Role;

sub import {
	shift;
	my $pkg = caller();
	
	# we should never export to main
	return if $pkg eq 'main';

	my $meta;
	if ($pkg->can('meta')) {
		$meta = $pkg->meta();
		(blessed($meta) && $meta->isa('Moose::Meta::Role'))
			|| confess "Whoops, not møøsey enough";
	}
	else {
		$meta = Moose::Meta::Role->new(role_name => $pkg);
		$meta->_role_meta->add_method('meta' => sub { $meta })		
	}
	
	# NOTE:
	# &alias_method will install the method, but it 
	# will not name it with 
	
	# handle superclasses
	$meta->alias_method('extends' => subname 'Moose::Role::extends' => sub { 
        confess "Moose::Role does not currently support 'extends'"
	});	
	
	# handle roles
	$meta->alias_method('with' => subname 'Moose::with' => sub { 
	    my ($role) = @_;
        Moose::_load_all_classes($role);
        $role->meta->apply($meta);
	});	
	
	# required methods
	$meta->alias_method('requires' => subname 'Moose::requires' => sub { 
        $meta->add_required_methods(@_);
	});	
	
	# handle attributes
	$meta->alias_method('has' => subname 'Moose::Role::has' => sub { 
		my ($name, %options) = @_;
		$meta->add_attribute($name, %options) 
	});

	# handle method modifers
	$meta->alias_method('before' => subname 'Moose::Role::before' => sub { 
		my $code = pop @_;
		$meta->add_before_method_modifier($_, $code) for @_;
	});
	$meta->alias_method('after'  => subname 'Moose::Role::after' => sub { 
		my $code = pop @_;
		$meta->add_after_method_modifier($_, $code) for @_;
	});	
	$meta->alias_method('around' => subname 'Moose::Role::around' => sub { 
		my $code = pop @_;
		$meta->add_around_method_modifier($_, $code) for @_;
	});	
	
	$meta->alias_method('super' => subname 'Moose::Role::super' => sub {});
	$meta->alias_method('override' => subname 'Moose::Role::override' => sub {
        my ($name, $code) = @_;
		$meta->add_override_method_modifier($name, $code);
	});		
	
	$meta->alias_method('inner' => subname 'Moose::Role::inner' => sub {
        confess "Moose::Role does not currently support 'inner'";	    
	});
	$meta->alias_method('augment' => subname 'Moose::Role::augment' => sub {
        confess "Moose::Role does not currently support 'augment'";
	});	

	# we recommend using these things 
	# so export them for them
	$meta->alias_method('confess' => \&Carp::confess);			
	$meta->alias_method('blessed' => \&Scalar::Util::blessed);    
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
  
  requires 'equal';
  
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
      $self->as_float == $other->as_float;
  }

=head1 DESCRIPTION

This is currently a very early release of Perl 6 style Roles for 
Moose, it is still incomplete, but getting much closer. If you are 
interested in helping move this feature along, please come to 
#moose on irc.perl.org and we can talk. 

=head1 CAVEATS

Currently, the role support has a few of caveats. They are as follows:

=over 4

=item *

At this time classes I<cannot> correctly consume more than one role. The 
role composition process, and it's conflict detection has not been added
yet. While this should be considered a major feature, it can easily be 
worked around, and in many cases, is not needed at all.
 
A class can actually consume multiple roles, they are just applied one 
after another in the order you ask for them. This is incorrect behavior, 
the roles should be merged first, and conflicts determined, etc. However, 
if your roles do not have any conflicts, then things will work just 
fine. This actually tends to be quite sufficient for basic roles.

=item *

Roles cannot use the C<extends> keyword, it will throw an exception for now. 
The same is true of the C<augment> and C<inner> keywords (not sure those 
really make sense for roles). All other Moose keywords will be I<deferred> 
so that they can be applied to the consuming class. 

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