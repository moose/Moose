
package Moose::Role;

use strict;
use warnings;

use Scalar::Util 'blessed';
use Carp         'confess';
use Sub::Name    'subname';

use Sub::Exporter;

our $VERSION = '0.05';

use Moose ();

use Moose::Meta::Role;
use Moose::Util::TypeConstraints;

{
    my ( $CALLER, %METAS );

    sub _find_meta {
        my $role = $CALLER;

        return $METAS{$role} if exists $METAS{$role};
        
        # make a subtype for each Moose class
        subtype $role
            => as 'Role'
            => where { $_->does($role) }
        unless find_type_constraint($role);        

    	my $meta;
    	if ($role->can('meta')) {
    		$meta = $role->meta();
    		(blessed($meta) && $meta->isa('Moose::Meta::Role'))
    			|| confess "Whoops, not møøsey enough";
    	}
    	else {
    		$meta = Moose::Meta::Role->new(role_name => $role);
    		$meta->_role_meta->add_method('meta' => sub { $meta })		
    	}

        return $METAS{$role} = $meta;
    }
 
	
    my %exports = (   
        extends => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::extends' => sub { 
                confess "Moose::Role does not currently support 'extends'"
	        };
	    },
	    with => sub {
	        my $meta = _find_meta();
	        return subname 'Moose::Role::with' => sub (@) { 
                my (@roles) = @_;
                confess "Must specify at least one role" unless @roles;
                Moose::_load_all_classes(@roles);
                ($_->can('meta') && $_->meta->isa('Moose::Meta::Role'))
                    || confess "You can only consume roles, $_ is not a Moose role"
                        foreach @roles;
                if (scalar @roles == 1) {
                    $roles[0]->meta->apply($meta);
                }
                else {
                    Moose::Meta::Role->combine(
                        map { $_->meta } @roles
                    )->apply($meta);
                }
            };
	    },	
        requires => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::requires' => sub (@) { 
                confess "Must specify at least one method" unless @_;
                $meta->add_required_methods(@_);
	        };
	    },	
        excludes => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::excludes' => sub (@) { 
                confess "Must specify at least one role" unless @_;
                $meta->add_excluded_roles(@_);
	        };
	    },	    
        has => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::has' => sub ($;%) { 
		        my ($name, %options) = @_;
		        $meta->add_attribute($name, %options) 
	        };
	    },
        before => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::before' => sub (@&) { 
                confess "Moose::Role does not currently support 'before'";
	        };
	    },
        after => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::after' => sub (@&) { 
                confess "Moose::Role does not currently support 'after'";
	        };
	    },
        around => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::around' => sub (@&) { 
                confess "Moose::Role does not currently support 'around'";
	        };
	    },
	    super => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::super' => sub {
                confess "Moose::Role cannot support 'super'";
            };
        },
        override => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::override' => sub ($&) {
                confess "Moose::Role cannot support 'override'";
	        };
	    },		
        inner => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::inner' => sub {
                confess "Moose::Role cannot support 'inner'";	    
	        };
	    },
        augment => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::augment' => sub {
                confess "Moose::Role cannot support 'augment'";
	        };
	    },
        confess => sub {
            return \&Carp::confess;
        },
        blessed => sub {
            return \&Scalar::Util::blessed;
        }	    
	);	

    my $exporter = Sub::Exporter::build_exporter({ 
        exports => \%exports,
        groups  => {
            default => [':all']
        }
    });
    
    sub import {
        $CALLER = caller();
        
        strict->import;
        warnings->import;        

        # we should never export to main
        return if $CALLER eq 'main';

        goto $exporter;
    };

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

Role support in Moose is coming along quite well. It's best documentation 
is still the the test suite, but it is fairly safe to assume Perl 6 style 
behavior, and then either refer to the test suite, or ask questions on 
#moose if something doesn't quite do what you expect. More complete 
documentation is planned and will be included with the next official 
(non-developer) release.

=head1 EXPORTED FUNCTIONS

Currently Moose::Role supports all of the functions that L<Moose> exports, 
but differs slightly in how some items are handled (see L<CAVEATS> below 
for details). 

Moose::Role also offers two role specific keyword exports:

=over 4

=item B<requires (@method_names)>

Roles can require that certain methods are implemented by any class which 
C<does> the role. 

=item B<excludes (@role_names)>

Roles can C<exclude> other roles, in effect saying "I can never be combined
with these C<@role_names>". This is a feature which should not be used 
lightly. 

=back

=head1 CAVEATS

The role support now has only a few caveats. They are as follows:

=over 4

=item *

Roles cannot use the C<extends> keyword, it will throw an exception for now. 
The same is true of the C<augment> and C<inner> keywords (not sure those 
really make sense for roles). All other Moose keywords will be I<deferred> 
so that they can be applied to the consuming class. 

=item * 

Role composition does it's best to B<not> be order sensitive when it comes
to conflict resolution and requirements detection. However, it is order 
sensitive when it comes to method modifiers. All before/around/after modifiers
are included whenever a role is composed into a class, and then are applied 
in the order the roles are used. This too means that there is no conflict for 
before/around/after modifiers as well. 

In most cases, this will be a non issue, however it is something to keep in 
mind when using method modifiers in a role. You should never assume any 
ordering.

=item *

The C<requires> keyword currently only works with actual methods. A method 
modifier (before/around/after and override) will not count as a fufillment 
of the requirement, and neither will an autogenerated accessor for an attribute.

It is likely that the attribute accessors will eventually be allowed to fufill 
those requirements, either that or we will introduce a C<requires_attr> keyword
of some kind instead. This descision has not yet been finalized.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Christian Hansen E<lt>chansen@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
