
package Moose::Meta::SafeMixin;

use strict;
use warnings;

use Scalar::Util 'blessed';
use Carp         'confess';

our $VERSION = '0.01';

use base 'Class::MOP::Class';

sub mixin {
    # fetch the metaclass for the 
    # caller and the mixin arg
    my $metaclass = shift;
    my $mixin     = $metaclass->initialize(shift);
    
    # according to Scala, the 
    # the superclass of our class
    # must be a subclass of the 
    # superclass of the mixin (see above)
    my ($super_meta)  = $metaclass->superclasses();
    my ($super_mixin) = $mixin->superclasses();  
    ($super_meta->isa($super_mixin))
        || confess "The superclass ($super_meta) must extend a subclass of the " . 
                   "superclass of the mixin ($super_mixin)"
			if defined $super_mixin && defined $super_meta;
    
    # check for conflicts here ...
    
    $metaclass->has_attribute($_) 
        && confess "Attribute conflict ($_)"
            foreach $mixin->get_attribute_list;

    foreach my $method_name ($mixin->get_method_list) {
        # skip meta, cause everyone has that :)
        next if $method_name =~ /meta/;
        $metaclass->has_method($method_name) && confess "Method conflict ($method_name)";
    }    
    
    # collect all the attributes
    # and clone them so they can 
    # associate with the new class                  
    # add all the attributes in ....
    foreach my $attr ($mixin->get_attribute_list) {
        $metaclass->add_attribute(
            $mixin->get_attribute($attr)->clone()
        );
    }     

    # add all the methods in ....    
    foreach my $method_name ($mixin->get_method_list) {
        # no need to mess with meta
        next if $method_name eq 'meta';
        my $method = $mixin->get_method($method_name);
        # and ignore accessors, the 
        # attributes take care of that
        next if blessed($method) && $method->isa('Class::MOP::Attribute::Accessor');
        $metaclass->alias_method($method_name => $method);
    }    
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::SafeMixin - A meta-object for safe mixin-style composition

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a meta-object which provides B<safe> mixin-style composition 
of classes. The key word here is "safe" because we enforce a number 
of rules about mixing in which prevent some of the instability 
inherent in other mixin systems. However, it should be noted that we 
still allow you enough rope with which to shoot yourself in the foot 
if you so desire.

=over 4

=item *

In order to mix classes together, they must inherit from a common 
superclass. This assures at least some level of similarity between 
the classes being mixed together, which should result in a more 
stable end product.

The only exception to this rule is if the class being mixed in has 
no superclasses at all. In this case we assume the mixin is valid.

=item * 

Since we enforce a common ancestral relationship, we need to be 
mindful of method and attribute conflicts. The common ancestor 
increases the potential of method conflicts because it is common 
for subclasses to override their parents methods. However, it is 
less common for attributes to be overriden. The way these are  
resolved is to use a Trait/Role-style conflict mechanism.

If two classes are mixed together, any method or attribute conflicts 
will result in a failure of the mixin and a fatal exception. It is 
not possible to resolve a method or attribute conflict dynamically. 
This is because to do so would open the possibility of breaking 
classes in very subtle and dangerous ways, particularly in the area 
of method interdependencies. The amount of implementation knowledge 
which would need to be known by the mixee would (IMO) increase the 
complexity of the feature exponentially for each class mixed in.

However fear not, there is a solution (see below) ...

=item *

Safe mixin's offer the possibility of CLOS style I<before>, I<after> 
and I<around> methods with which method conflicts can be resolved. 

A method, which would normally conflict, but which is labeled with 
either a I<before>, I<after> or I<around> attribute, will instead be 
combined with the original method in the way implied by the attribute.

The result of this is a generalized event-handling system for classes. 
Which can be used to create things more specialized, such as plugins 
and decorators.

=back

=head2 What kinda crack are you on ?!?!?!?

This approach may seem crazy, but I am fairly confident that it will 
work, and that it will not tie your hands unnessecarily. All these 
features have been used with certain degrees of success in the object 
systems of other languages, but none (IMO) provided a complete 
solution.

In CLOS, I<before>, I<after> and I<around> methods provide a high 
degree of flexibility for adding behavior to methods, but do not address 
any concerns regarding classes since in CLOS, classes and methods are 
separate components of the system.

In Scala, mixins are restricted by their ancestral relationships, which 
results in a need to have seperate "traits" to get around this restriction. 
In addition, Scala does not seem to have any means of method conflict 
resolution for mixins (at least not that I can find).

In Perl 6, the role system forces manual disambiguation which (as 
mentioned above) can cause issues with method interdependecies when 
composing roles together. This problem will grow exponentially in one 
direction with each role composed and in the other direction with the 
number of roles that role itself is composed of. The result is that the 
complexity of the system becomes unmanagable for all but very simple or
very shallow roles. Now, this is not to say that roles are unusable, in 
fact, this feature (IMO) promotes good useage of roles by keeping them 
both small and simple. But, the same behaviors cannot be applied to 
class mixins without hitting these barriers all too quickly.

The same too can be said of the original Traits system, with its 
features for aliasing and exclusion of methods. 

So after close study of these systems, and in some cases actually 
implementing said systems, I have come to the see that each on it's 
own is not robust enough and that combining the best parts of each 
gives us (what I hope is) a better, safer and saner system.

=head1 METHODS

=over 4

=item B<mixin ($mixin)>

=back

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
