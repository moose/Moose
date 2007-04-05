
package Moose;

use strict;
use warnings;

our $VERSION   = '0.19';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util 'blessed', 'reftype';
use Carp         'confess';
use Sub::Name    'subname';
use B            'svref_2object';

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
            => optimize_as { blessed($_[0]) && $_[0]->isa($class) }
        unless find_type_constraint($class);

        my $meta;
        if ($class->can('meta')) {
            # NOTE:
            # this is the case where the metaclass pragma 
            # was used before the 'use Moose' statement to 
            # override a specific class
            $meta = $class->meta();
            (blessed($meta) && $meta->isa('Moose::Meta::Class'))
                || confess "You already have a &meta function, but it does not return a Moose::Meta::Class";
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
                Class::MOP::load_class($_) for @_;
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
                Class::MOP::load_class($_) for @roles;
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
        
        # NOTE:
        # this is experimental, but I am not 
        # happy with it. If you want to try 
        # it, you will have to uncomment it 
        # yourself. 
        # There is a really good chance that 
        # this will be deprecated, dont get 
        # too attached
        # self => sub {
        #     return subname 'Moose::self' => sub {};
        # },        
        # method => sub {
        #     my $class = $CALLER;
        #     return subname 'Moose::method' => sub {
        #         my ($name, $method) = @_;
        #         $class->meta->add_method($name, sub {
        #             my $self = shift;
        #             no strict   'refs';
        #             no warnings 'redefine';
        #             local *{$class->meta->name . '::self'} = sub { $self };
        #             $method->(@_);
        #         });
        #     };
        # },                
        
        confess => sub {
            return \&Carp::confess;
        },
        blessed => sub {
            return \&Scalar::Util::blessed;
        },
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
    
    sub unimport {
        no strict 'refs';        
        my $class = caller();
        # loop through the exports ...
        foreach my $name (keys %exports) {
            next if $name =~ /inner|super|self/;
            
            # if we find one ...
            if (defined &{$class . '::' . $name}) {
                my $keyword = \&{$class . '::' . $name};
                
                # make sure it is from Moose
                my $pkg_name = eval { svref_2object($keyword)->GV->STASH->NAME };
                next if $@;
                next if $pkg_name ne 'Moose';
                
                # and if it is from Moose then undef the slot
                delete ${$class . '::'}{$name};
            }
        }
    }
    
    
}

## make 'em all immutable

$_->meta->make_immutable(
    inline_constructor => 0,
    inline_accessors   => 0,    
) for (
    'Moose::Meta::Attribute',
    'Moose::Meta::Class',
    'Moose::Meta::Instance',

    'Moose::Meta::TypeConstraint',
    'Moose::Meta::TypeConstraint::Union',
    'Moose::Meta::TypeCoercion',

    'Moose::Meta::Method',
    'Moose::Meta::Method::Accessor',
    'Moose::Meta::Method::Constructor',
    'Moose::Meta::Method::Overriden',
);

1;

__END__

=pod

=head1 NAME

Moose - A complete modern object system for Perl 5

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

=head1 DESCRIPTION

Moose is an extension of the Perl 5 object system. 

=head2 Another object system!?!?

Yes, I know there has been an explosion recently of new ways to 
build object's in Perl 5, most of them based on inside-out objects
and other such things. Moose is different because it is not a new 
object system for Perl 5, but instead an extension of the existing 
object system.

Moose is built on top of L<Class::MOP>, which is a metaclass system 
for Perl 5. This means that Moose not only makes building normal 
Perl 5 objects better, but it also provides the power of metaclass 
programming.

=head2 Is this for real? Or is this just an experiment?

Moose is I<based> on the prototypes and experiments I did for the Perl 6
meta-model; however Moose is B<NOT> an experiment/prototype, it is 
for B<real>. 

=head2 Is this ready for use in production? 

Yes, I believe that it is. 

I have two medium-to-large-ish web applications which use Moose heavily
and have been in production (without issue) for several months now. At 
$work, we are re-writing our core offering in it. And several people on 
#moose have been using it (in production) for several months now as well.

Of course, in the end, you need to make this call yourself. If you have 
any questions or concerns, please feel free to email me, or even the list 
or just stop by #moose and ask away.

=head2 Is Moose just Perl 6 in Perl 5?

No. While Moose is very much inspired by Perl 6, it is not itself Perl 6.
Instead, it is an OO system for Perl 5. I built Moose because I was tired or
writing the same old boring Perl 5 OO code, and drooling over Perl 6 OO. So
instead of switching to Ruby, I wrote Moose :)

=head1 BUILDING CLASSES WITH MOOSE

Moose makes every attempt to provide as much convenience as possible during
class construction/definition, but still stay out of your way if you want it
to. Here are a few items to note when building classes with Moose.

Unless specified with C<extends>, any class which uses Moose will 
inherit from L<Moose::Object>.

Moose will also manage all attributes (including inherited ones) that 
are defined with C<has>. And assuming that you call C<new>, which is 
inherited from L<Moose::Object>, then this includes properly initializing 
all instance slots, setting defaults where appropriate, and performing any 
type constraint checking or coercion. 

=head1 EXPORTED FUNCTIONS

Moose will export a number of functions into the class's namespace which 
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
superclasses still properly inherit from L<Moose::Object>.

=item B<with (@roles)>

This will apply a given set of C<@roles> to the local class. Role support 
is currently under heavy development; see L<Moose::Role> for more details.

=item B<has $name =E<gt> %options>

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
string. The string can be either a class name or a type defined using 
Moose's type definition features.

=item I<coerce =E<gt> (1|0)>

This will attempt to use coercion with the supplied type constraint to change 
the value passed into any accessors or constructors. You B<must> have supplied 
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

This will tell the class to store the value of this attribute as a weakened
reference. If an attribute is a weakened reference, it B<cannot> also be
coerced.

=item I<lazy =E<gt> (1|0)>

This will tell the class to not create this slot until absolutely necessary. 
If an attribute is marked as lazy it B<must> have a default supplied.

=item I<auto_deref =E<gt> (1|0)>

This tells the accessor whether to automatically dereference the value returned. 
This is only legal if your C<isa> option is either an C<ArrayRef> or C<HashRef>.

=item I<metaclass =E<gt> $metaclass_name>

This tells the class to use a custom attribute metaclass for this particular 
attribute. Custom attribute metaclasses are useful for extending the capabilities 
of the I<has> keyword, they are the simplest way to extend the MOP, but they are 
still a fairly advanced topic and too much to cover here. I will try and write a 
recipe on it soon.

The default behavior here is to just load C<$metaclass_name>, however, we also 
have a way to alias to a shorter name. This will first look to see if 
B<Moose::Meta::Attribute::Custom::$metaclass_name> exists, if it does it will 
then check to see if that has the method C<register_implemenetation> which 
should return the actual name of the custom attribute metaclass. If there is 
no C<register_implemenetation> method, it will just default to using 
B<Moose::Meta::Attribute::Custom::$metaclass_name> as the metaclass name.

=item I<trigger =E<gt> $code>

The trigger option is a CODE reference which will be called after the value of 
the attribute is set. The CODE ref will be passed the instance itself, the 
updated value and the attribute meta-object (this is for more advanced fiddling
and can typically be ignored in most cases). You B<cannot> have a trigger on
a read-only attribute.

=item I<handles =E<gt> ARRAY | HASH | REGEXP | CODE>

The handles option provides Moose classes with automated delegation features. 
This is a pretty complex and powerful option, it accepts many different option 
formats, each with it's own benefits and drawbacks. 

B<NOTE:> This features is no longer experimental, but it still may have subtle 
bugs lurking in the deeper corners. So if you think you have found a bug, you 
probably have, so please report it to me right away. 

B<NOTE:> The class being delegated to does not need to be a Moose based class. 
Which is why this feature is especially useful when wrapping non-Moose classes.

All handles option formats share the following traits. 

You cannot override a locally defined method with a delegated method, an 
exception will be thrown if you try. Meaning, if you define C<foo> in your 
class, you cannot override it with a delegated C<foo>. This is almost never 
something you would want to do, and if it is, you should do it by hand and 
not use Moose.

You cannot override any of the methods found in Moose::Object as well as 
C<BUILD> or C<DEMOLISH> methods. These will not throw an exception, but will 
silently move on to the next method in the list. My reasoning for this is that 
you would almost never want to do this because it usually tends to break your 
class. And as with overriding locally defined methods, if you do want to do this, 
you should do it manually and not with Moose.

Below is the documentation for each option format:

=over 4

=item C<ARRAY>

This is the most common usage for handles. You basically pass a list of 
method names to be delegated, and Moose will install a delegation method 
for each one in the list.

=item C<HASH>

This is the second most common usage for handles. Instead of a list of 
method names, you pass a HASH ref where the key is the method name you 
want installed locally, and the value is the name of the original method 
in the class being delegated too. 

This can be very useful for recursive classes like trees, here is a 
quick example (soon to be expanded into a Moose::Cookbook::Recipe):

  pacakge Tree;
  use Moose;
  
  has 'node' => (is => 'rw', isa => 'Any');
  
  has 'children' => (
      is      => 'ro',
      isa     => 'ArrayRef',
      default => sub { [] }
  );
  
  has 'parent' => (
      is          => 'rw',
      isa         => 'Tree',
      is_weak_ref => 1,
      handles     => {
          parent_node => 'node',
          siblings    => 'children', 
      }
  );

In this example, the Tree package gets the C<parent_node> and C<siblings> methods
which delegate to the C<node> and C<children> methods of the Tree instance stored 
in the parent slot. 

=item C<REGEXP>

The regexp option works very similar to the ARRAY option, except that it builds 
the list of methods for you. It starts by collecting all possible methods of the 
class being delegated too, then filters that list using the regexp supplied here. 

B<NOTE:> An I<isa> option is required when using the regexp option format. This 
is so that we can determine (at compile time) the method list from the class. 
Without an I<isa> this is just not possible.

=item C<CODE>

This is the option to use when you really want to do something funky. You should 
only use it if you really know what you are doing as it involves manual metaclass
twiddling.

This takes a code reference, which should expect two arguments. The first is 
the attribute meta-object this I<handles> is attached too. The second is the metaclass
of the class being delegated too. It expects you to return a hash (not a HASH ref)
of the methods you want mapped. 

=back

=back

=item B<has +$name =E<gt> %options>

This is variation on the normal attibute creator C<has>, which allows you to 
clone and extend an attribute from a superclass. Here is a quick example:

  package Foo;
  use Moose;
  
  has 'message' => (
      is      => 'rw', 
      isa     => 'Str',
      default => 'Hello, I am a Foo'
  );
  
  package My::Foo;
  use Moose;
  
  extends 'Foo';
  
  has '+message' => (default => 'Hello I am My::Foo');

What is happening here is that B<My::Foo> is cloning the C<message> attribute 
from it's parent class B<Foo>, retaining the is =E<gt> 'rw' and isa =E<gt> 'Str'
characteristics, but changing the value in C<default>.

This feature is restricted somewhat, so as to try and enfore at least I<some>
sanity into it. You are only allowed to change the following attributes:

=over 4

=item I<default> 

Change the default value of an attribute.

=item I<coerce> 

Change whether the attribute attempts to coerce a value passed to it.

=item I<required> 

Change if the attribute is required to have a value.

=item I<documentation>

Change the documentation string associated with the attribute.

=item I<isa>

You I<are> allowed to change the type, but if and B<only if> the new type is
a subtype of the old type.  

=back

=item B<before $name|@names =E<gt> sub { ... }>

=item B<after $name|@names =E<gt> sub { ... }>

=item B<around $name|@names =E<gt> sub { ... }>

This three items are syntactic sugar for the before, after, and around method 
modifier features that L<Class::MOP> provides. More information on these can 
be found in the L<Class::MOP> documentation for now. 

=item B<super>

The keyword C<super> is a no-op when called outside of an C<override> method. In  
the context of an C<override> method, it will call the next most appropriate 
superclass method with the same arguments as the original method.

=item B<override ($name, &sub)>

An C<override> method is a way of explicitly saying "I am overriding this 
method from my superclass". You can call C<super> within this method, and 
it will work as expected. The same thing I<can> be accomplished with a normal 
method call and the C<SUPER::> pseudo-package; it is really your choice. 

=item B<inner>

The keyword C<inner>, much like C<super>, is a no-op outside of the context of 
an C<augment> method. You can think of C<inner> as being the inverse of 
C<super>; the details of how C<inner> and C<augment> work is best described in
the L<Moose::Cookbook>.

=item B<augment ($name, &sub)>

An C<augment> method, is a way of explicitly saying "I am augmenting this 
method from my superclass". Once again, the details of how C<inner> and 
C<augment> work is best described in the L<Moose::Cookbook>.

=item B<confess>

This is the C<Carp::confess> function, and exported here because I use it
all the time. This feature may change in the future, so you have been warned. 

=item B<blessed>

This is the C<Scalar::Uti::blessed> function, it is exported here because I
use it all the time. It is highly recommended that this is used instead of 
C<ref> anywhere you need to test for an object's class name.

=back

=head1 UNEXPORTING FUNCTIONS

=head2 B<unimport>

Moose offers a way of removing the keywords it exports though the C<unimport>
method. You simply have to say C<no Moose> at the bottom of your code for this
to work. Here is an example:

    package Person;
    use Moose;

    has 'first_name' => (is => 'rw', isa => 'Str');
    has 'last_name'  => (is => 'rw', isa => 'Str');
    
    sub full_name { 
        my $self = shift;
        $self->first_name . ' ' . $self->last_name 
    }
    
    no Moose; # keywords are removed from the Person package    

=head1 MISC.

=head2 What does Moose stand for??

Moose doesn't stand for one thing in particular, however, if you 
want, here are a few of my favorites; feel free to contribute
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

It should be noted that C<super> and C<inner> C<cannot> be used in the same 
method. However, they can be combined together with the same class hierarchy;
see F<t/014_override_augment_inner_super.t> for an example. 

The reason for this is that C<super> is only valid within a method 
with the C<override> modifier, and C<inner> will never be valid within an 
C<override> method. In fact, C<augment> will skip over any C<override> methods 
when searching for its appropriate C<inner>.

This might seem like a restriction, but I am of the opinion that keeping these 
two features separate (but interoperable) actually makes them easy to use, since 
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
ideas/feature-requests/encouragement/bug-finding.

=item Thanks to David "Theory" Wheeler for meta-discussions and spelling fixes.

=back

=head1 SEE ALSO

=over 4

=item L<Class::MOP> documentation

=item The #moose channel on irc.perl.org

=item The Moose mailing list - moose@perl.org

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

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
