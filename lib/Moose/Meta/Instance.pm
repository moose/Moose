package Moose::Meta::Instance;
our $VERSION = '2.2006';

use strict;
use warnings;

use Class::MOP::MiniTrait;

use parent 'Class::MOP::Instance';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

1;

# ABSTRACT: The Moose Instance metaclass

__END__

=pod

=head1 DESCRIPTION

The Instance Protocol controls the creation of object instances, and
the storage of attribute values in those instances.

Using this API directly in your own code violates encapsulation, and
we recommend that you use the appropriate APIs in L<Class::MOP::Class>
and L<Class::MOP::Attribute> instead. Those APIs in turn call the
methods in this class as appropriate.

This class also participates in generating inlined code by providing
snippets of code to access an object instance.

=head1 INHERITANCE

C<Moose::Meta::Instance> is a subclass of L<Class::MOP::Instance>. All of the
methods provided by both classes are documented here.

=head1 METHODS

This class provides the following methods.

=head2 Class::MOP::Instance->new(%options)

This method creates a new meta-instance object.

It accepts the following keys in C<%options>:

=over 4

=item * associated_metaclass

The L<Class::MOP::Class> object for which instances will be created.

=item * attributes

An array reference of L<Class::MOP::Attribute> objects. These are the
attributes which can be stored in each instance.

=back

=head2 Creating and altering instances

These methods allow you to create instances and alter them.

=head3 $metainstance->create_instance

This method returns a reference blessed into the associated
metaclass's class.

The default is to use a hash reference. Subclasses can override this.

=head3 $metainstance->clone_instance($instance)

Given an instance, this method creates a new object by making
I<shallow> clone of the original.

=head2 Introspection

These methods give you information about the meta instance object.

=head3 $metainstance->associated_metaclass

This returns the L<Class::MOP::Class> object associated with the
meta-instance object.

=head3 $metainstance->get_all_slots

This returns a list of slot names stored in object instances. In
almost all cases, slot names correspond directly attribute names.

=head3 $metainstance->is_valid_slot($slot_name)

This will return true if C<$slot_name> is a valid slot name.

=head3 $metainstance->get_all_attributes

This returns a list of attributes corresponding to the attributes
passed to the constructor.

=head2 Operations on Instance Structures

It's important to understand that the meta-instance object is a different
entity from the actual instances it creates. For this reason, any operations
on the C<$instance_structure> always require that the object instance be
passed to the method.

The exact details of what each method does should be fairly obvious from the
method name.

=over 4

=item * $metainstance->get_slot_value($instance_structure, $slot_name)

=item * $metainstance->set_slot_value($instance_structure, $slot_name, $value)

=item * $metainstance->initialize_slot($instance_structure, $slot_name)

=item * $metainstance->deinitialize_slot($instance_structure, $slot_name)

=item * $metainstance->initialize_all_slots($instance_structure)

=item * $metainstance->deinitialize_all_slots($instance_structure)

=item * $metainstance->is_slot_initialized($instance_structure, $slot_name)

=item * $metainstance->weaken_slot_value($instance_structure, $slot_name)

=item * $metainstance->slot_value_is_weak($instance_structure, $slot_name)

=item * $metainstance->strengthen_slot_value($instance_structure, $slot_name)

=item * $metainstance->rebless_instance_structure($instance_structure, $new_metaclass)

=back

=head2 Inlinable Instance Operations

These methods return code snippets used when generating inlined accessors and
constructors.

=head3 $metainstance->is_inlinable

This is a boolean that indicates whether or not slot access operations
can be inlined. By default it is true, but subclasses can override
this.

=head3 $metainstance->inline_create_instance($class_variable)

This method expects a string that, I<when inlined>, will become a
class name. This would literally be something like C<'$class'>, not an
actual class name.

It returns a snippet of code that creates a new object for the
class. This is something like C< bless {}, $class_name >.

=head3 $metainstance->inline_get_is_lvalue

Returns whether or not C<inline_get_slot_value> is a valid lvalue. This can be
used to do extra optimizations when generating inlined methods.

=head3 Inline slot manipulation methods

These methods all expect two arguments. The first is the name of a variable,
than when inlined, will represent the object instance. Typically this will be
a literal string like C<'$_[0]'>.

The second argument is a slot name, which is typically the name of an
attribute.

These methods return a snippet of code that, when inlined, performs some
operation on the instance.

=over 4

=item * $metainstance->inline_slot_access($instance_variable, $slot_name)

=item * $metainstance->inline_get_slot_value($instance_variable, $slot_name)

=item * $metainstance->inline_set_slot_value($instance_variable, $slot_name, $value)

=item * $metainstance->inline_initialize_slot($instance_variable, $slot_name)

=item * $metainstance->inline_deinitialize_slot($instance_variable, $slot_name)

=item * $metainstance->inline_is_slot_initialized($instance_variable, $slot_name)

=item * $metainstance->inline_weaken_slot_value($instance_variable, $slot_name)

=item * $metainstance->inline_strengthen_slot_value($instance_variable, $slot_name)

=back

=head3 $metainstance->inline_rebless_instance_structure($instance_variable, $class_variable)

This takes the name of a variable that will, when inlined, represent the object
instance, and the name of a variable that will represent the class to rebless
into, and returns code to rebless an instance into a class.

=head2 Class::MOP::Instance->meta

This will return a L<Class::MOP::Class> instance for this class.

It should also be noted that L<Class::MOP> will actually bootstrap
this module by installing a number of attribute meta-objects into its
metaclass.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
