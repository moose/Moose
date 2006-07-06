
package Moose;

use strict;
use warnings;

our $VERSION = '0.10';

use Scalar::Util 'blessed', 'reftype';
use Carp         'confess';
use Sub::Name    'subname';

use UNIVERSAL::require;
use Sub::Exporter;

use Class::MOP;

use Moose::Meta::Class;
use Moose::Meta::TypeConstraint;
use Moose::Meta::TypeCoercion;
use Moose::Meta::Attribute;
use Moose::Meta::Instance;

use Moose::Object;
use Moose::Util::TypeConstraints;

{
    my $CALLER;

    sub _init_meta {
        my $class = $CALLER;

        # make a subtype for each Moose class
        subtype $class
            => as 'Object'
            => where { $_->isa($class) }
        unless find_type_constraint($class);

        my $meta;
        if ($class->can('meta')) {
            # NOTE:
            # this is the case where the metaclass pragma 
            # was used before the 'use Moose' statement to 
            # override a specific class
            $meta = $class->meta();
            (blessed($meta) && $meta->isa('Moose::Meta::Class'))
                || confess "Whoops, not møøsey enough";
        }
        else {
            # NOTE:
            # this is broken currently, we actually need 
            # to allow the possiblity of an inherited 
            # meta, which will not be visible until the 
            # user 'extends' first. This needs to have 
            # more intelligence to it 
            $meta = Moose::Meta::Class->initialize($class);
            $meta->add_method('meta' => sub {
                # re-initialize so it inherits properly
                Moose::Meta::Class->initialize(blessed($_[0]) || $_[0]);
            })
        }

        # make sure they inherit from Moose::Object
        $meta->superclasses('Moose::Object')
           unless $meta->superclasses();
    }

    my %exports = (
        extends => sub {
            my $class = $CALLER;
            return subname 'Moose::extends' => sub (@) {
                confess "Must derive at least one class" unless @_;
                _load_all_classes(@_);
                # this checks the metaclass to make sure 
                # it is correct, sometimes it can get out 
                # of sync when the classes are being built
                my $meta = $class->meta->_fix_metaclass_incompatability(@_);
                $meta->superclasses(@_);
            };
        },
        with => sub {
            my $class = $CALLER;
            return subname 'Moose::with' => sub (@) {
                my (@roles) = @_;
                confess "Must specify at least one role" unless @roles;
                _load_all_classes(@roles);
                $class->meta->_apply_all_roles(@roles);
            };
        },
        has => sub {
            my $class = $CALLER;
            return subname 'Moose::has' => sub ($;%) {
                my ($name, %options) = @_;              
                $class->meta->_process_attribute($name, %options);
            };
        },
        before => sub {
            my $class = $CALLER;
            return subname 'Moose::before' => sub (@&) {
                my $code = pop @_;
                my $meta = $class->meta;
                $meta->add_before_method_modifier($_, $code) for @_;
            };
        },
        after => sub {
            my $class = $CALLER;
            return subname 'Moose::after' => sub (@&) {
                my $code = pop @_;
                my $meta = $class->meta;
                $meta->add_after_method_modifier($_, $code) for @_;
            };
        },
        around => sub {
            my $class = $CALLER;            
            return subname 'Moose::around' => sub (@&) {
                my $code = pop @_;
                my $meta = $class->meta;
                $meta->add_around_method_modifier($_, $code) for @_;
            };
        },
        super => sub {
            return subname 'Moose::super' => sub {};
        },
        override => sub {
            my $class = $CALLER;
            return subname 'Moose::override' => sub ($&) {
                my ($name, $method) = @_;
                $class->meta->add_override_method_modifier($name => $method);
            };
        },
        inner => sub {
            return subname 'Moose::inner' => sub {};
        },
        augment => sub {
            my $class = $CALLER;
            return subname 'Moose::augment' => sub (@&) {
                my ($name, $method) = @_;
                $class->meta->add_augment_method_modifier($name => $method);
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
    
        _init_meta();
        
        goto $exporter;
    }
}

## Utility functions

sub _load_all_classes {
    foreach my $super (@_) {
        # see if this is already 
        # loaded in the symbol table
        next if _is_class_already_loaded($super);
        # otherwise require it ...
        ($super->require)
            || confess "Could not load module '$super' because : " . $UNIVERSAL::require::ERROR;
    }    
}

sub _is_class_already_loaded {
	my $name = shift;
	no strict 'refs';
	return 1 if defined ${"${name}::VERSION"} || defined @{"${name}::ISA"};
	foreach (keys %{"${name}::"}) {
		next if substr($_, -2, 2) eq '::';
		return 1 if defined &{"${name}::$_"};
	}
    return 0;
}

1;

__END__

=pod

=head1 NAME

Moose - Moose, it's the new Camel

=head1 SYNOPSIS

  package Point;
  use strict;
  use warnings;
  use Moose;
  	
  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');
  
  sub clear {
      my $self = shift;
      $self->x(0);
      $self->y(0);    
  }
  
  package Point3D;
  use strict;
  use warnings;  
  use Moose;
  
  extends 'Point';
  
  has 'z' => (is => 'rw', isa => 'Int');
  
  after 'clear' => sub {
      my $self = shift;
      $self->z(0);
  };
  
=head1 CAVEAT

Moose is a rapidly maturing module, and is already being used by 
a number of people. It's test suite is growing larger by the day, 
and the docs should soon follow. 

This said, Moose is not yet finished, and should still be considered 
to be evolving. Much of the outer API is stable, but the internals 
are still subject to change (although not without serious thought 
given to it).  

For more details, please refer to the L<FUTURE PLANS> section of 
this document.

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

=head2 Can I use this in production? Or is this just an experiment?

Moose is I<based> on the prototypes and experiments I did for the Perl 6
meta-model, however Moose is B<NOT> an experiment/prototype, it is 
for B<real>. I will be deploying Moose into production environments later 
this year, and I have all intentions of using it as my de-facto class 
builderfrom now on. 

=head2 Is Moose just Perl 6 in Perl 5?

No. While Moose is very much inspired by Perl 6, it is not. Instead, it  
is an OO system for Perl 5. I built Moose because I was tired or writing 
the same old boring Perl 5 OO code, and drooling over Perl 6 OO. So 
instead of switching to Ruby, I wrote Moose :) 

=head1 BUILDING CLASSES WITH MOOSE

Moose makes every attempt to provide as much convience during class 
construction/definition, but still stay out of your way if you want 
it to. Here are a few items to note when building classes with Moose.

Unless specified with C<extends>, any class which uses Moose will 
inherit from L<Moose::Object>.

Moose will also manage all attributes (including inherited ones) that 
are defined with C<has>. And assuming that you call C<new> which is 
inherited from L<Moose::Object>, then this includes properly initializing 
all instance slots, setting defaults where approprtiate and performing any 
type constraint checking or coercion. 

=head1 EXPORTED FUNCTIONS

Moose will export a number of functions into the class's namespace, which 
can then be used to set up the class. These functions all work directly 
on the current class.

=over 4

=item B<meta>

This is a method which provides access to the current class's metaclass.

=item B<extends (@superclasses)>

This function will set the superclass(es) for the current class.

This approach is recommended instead of C<use base>, because C<use base> 
actually C<push>es onto the class's C<@ISA>, whereas C<extends> will 
replace it. This is important to ensure that classes which do not have 
superclasses properly inherit from L<Moose::Object>.

=item B<with (@roles)>

This will apply a given set of C<@roles> to the local class. Role support 
is currently under heavy development, see L<Moose::Role> for more details.

=item B<has ($name, %options)>

This will install an attribute of a given C<$name> into the current class. 
The list of C<%options> are the same as those provided by 
L<Class::MOP::Attribute>, in addition to the list below which are provided 
by Moose (L<Moose::Meta::Attribute> to be more specific):

=over 4

=item I<is =E<gt> 'rw'|'ro'>

The I<is> option accepts either I<rw> (for read/write) or I<ro> (for read 
only). These will create either a read/write accessor or a read-only 
accessor respectively, using the same name as the C<$name> of the attribute.

If you need more control over how your accessors are named, you can use the 
I<reader>, I<writer> and I<accessor> options inherited from L<Class::MOP::Attribute>.

=item I<isa =E<gt> $type_name>

The I<isa> option uses Moose's type constraint facilities to set up runtime 
type checking for this attribute. Moose will perform the checks during class 
construction, and within any accessors. The C<$type_name> argument must be a 
string. The string can be either a class name, or a type defined using 
Moose's type defintion features.

=item I<coerce =E<gt> (1|0)>

This will attempt to use coercion with the supplied type constraint to change 
the value passed into any accessors of constructors. You B<must> have supplied 
a type constraint in order for this to work. See L<Moose::Cookbook::Recipe5>
for an example usage.

=item I<does =E<gt> $role_name>

This will accept the name of a role which the value stored in this attribute 
is expected to have consumed.

=item I<required =E<gt> (1|0)>

This marks the attribute as being required. This means a value must be supplied 
during class construction, and the attribute can never be set to C<undef> with 
an accessor. 

=item I<weak_ref =E<gt> (1|0)>

This will tell the class to strore the value of this attribute as a weakened 
reference. If an attribute is a weakened reference, it can B<not> also be coerced. 

=item I<lazy =E<gt> (1|0)>

This will tell the class to not create this slot until absolutely nessecary. 
If an attribute is marked as lazy it B<must> have a default supplied.

=item I<auto_deref =E<gt> (1|0)>

This tells the accessor whether to automatically de-reference the value returned. 
This is only legal if your C<isa> option is either an C<ArrayRef> or C<HashRef>.

=item I<trigger =E<gt> $code>

The trigger option is a CODE reference which will be called after the value of 
the attribute is set. The CODE ref will be passed the instance itself, the 
updated value and the attribute meta-object (this is for more advanced fiddling
and can typically be ignored in most cases). You can B<not> have a trigger on 
a read-only attribute.

=item I<handles =E<gt> [ @handles ]>

There is experimental support for attribute delegation using the C<handles> 
option. More docs to come later.

=back

=item B<before $name|@names =E<gt> sub { ... }>

=item B<after $name|@names =E<gt> sub { ... }>

=item B<around $name|@names =E<gt> sub { ... }>

This three items are syntactic sugar for the before, after and around method 
modifier features that L<Class::MOP> provides. More information on these can 
be found in the L<Class::MOP> documentation for now. 

=item B<super>

The keyword C<super> is a noop when called outside of an C<override> method. In 
the context of an C<override> method, it will call the next most appropriate 
superclass method with the same arguments as the original method.

=item B<override ($name, &sub)>

An C<override> method, is a way of explictly saying "I am overriding this 
method from my superclass". You can call C<super> within this method, and 
it will work as expected. The same thing I<can> be accomplished with a normal 
method call and the C<SUPER::> pseudo-package, it is really your choice. 

=item B<inner>

The keyword C<inner>, much like C<super>, is a no-op outside of the context of 
an C<augment> method. You can think of C<inner> as being the inverse of 
C<super>, the details of how C<inner> and C<augment> work is best described in 
the L<Moose::Cookbook>.

=item B<augment ($name, &sub)>

An C<augment> method, is a way of explictly saying "I am augmenting this 
method from my superclass". Once again, the details of how C<inner> and 
C<augment> work is best described in the L<Moose::Cookbook>.

=item B<confess>

This is the C<Carp::confess> function, and exported here beause I use it 
all the time. This feature may change in the future, so you have been warned. 

=item B<blessed>

This is the C<Scalar::Uti::blessed> function, it is exported here beause I 
use it all the time. It is highly recommended that this is used instead of 
C<ref> anywhere you need to test for an object's class name.

=back

=head1 FUTURE PLANS

Here is just a sampling of the plans we have in store for Moose:

=over 4

=item *

Compiling Moose classes/roles into C<.pmc> files for faster loading and execution.

=item * 

Supporting sealed and finalized classes in Moose. This will allow greater control 
of the extensions of frameworks and such.

=back

=head1 MISC.

=head2 What does Moose stand for??

Moose doesn't stand for one thing in particular, however, if you 
want, here are a few of my favorites, feel free to contribute 
more :)

=over 4

=item Make Other Object Systems Envious

=item Makes Object Orientation So Easy

=item Makes Object Orientation Spiffy- Er  (sorry ingy)

=item Most Other Object Systems Emasculate

=item Moose Often Ovulate Sorta Early

=item Moose Offers Often Super Extensions

=item Meta Object Orientation Syntax Extensions

=back

=head1 CAVEATS

=over 4

=item *

It should be noted that C<super> and C<inner> can B<not> be used in the same 
method. However, they can be combined together with the same class hierarchy, 
see F<t/014_override_augment_inner_super.t> for an example. 

The reason that this is so is because C<super> is only valid within a method 
with the C<override> modifier, and C<inner> will never be valid within an 
C<override> method. In fact, C<augment> will skip over any C<override> methods 
when searching for it's appropriate C<inner>. 

This might seem like a restriction, but I am of the opinion that keeping these 
two features seperate (but interoperable) actually makes them easy to use since 
their behavior is then easier to predict. Time will tell if I am right or not.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item I blame Sam Vilain for introducing me to the insanity that is meta-models.

=item I blame Audrey Tang for then encouraging my meta-model habit in #perl6.

=item Without Yuval "nothingmuch" Kogman this module would not be possible, 
and it certainly wouldn't have this name ;P

=item The basis of the TypeContraints module was Rob Kinyon's idea 
originally, I just ran with it.

=item Thanks to mst & chansen and the whole #moose poose for all the 
ideas/feature-requests/encouragement

=back

=head1 SEE ALSO

=over 4

=item L<Class::MOP> documentation

=item The #moose channel on irc.perl.org

=item L<http://forum2.org/moose/>

=item L<http://www.cs.utah.edu/plt/publications/oopsla04-gff.pdf>

This paper (suggested by lbr on #moose) was what lead to the implementation 
of the C<super>/C<overrride> and C<inner>/C<augment> features. If you really 
want to understand this feature, I suggest you read this.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Christian Hansen E<lt>chansen@cpan.orgE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
