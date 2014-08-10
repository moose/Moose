package Moose::Meta::Method;
our $VERSION = '2.2006';

use strict;
use warnings;

use Class::MOP::MiniTrait;

use parent 'Class::MOP::Method';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

1;

# ABSTRACT: A Moose Method metaclass

__END__

=pod

=head1 DESCRIPTION

The Method Protocol is very small, since methods in Perl 5 are just
subroutines in a specific package. We provide a very basic introspection
interface.

=head1 INHERITANCE

C<Moose::Meta::Method> is a subclass of L<Class::MOP::Method>. All of the
methods provided by both classes are documented here.

=head1 METHODS

This class provides the following methods.

=head2 Moose::Meta::Method->wrap($code, %options)

This is the constructor. It accepts a method body in the form of
either a code reference or a L<Moose::Meta::Method> instance, followed
by a hash of options.

The options are:

=over 4

=item * name

The method name (without a package name). This is required if C<$code>
is a coderef.

=item * package_name

The package name for the method. This is required if C<$code> is a
coderef.

=item * associated_metaclass

An optional L<Class::MOP::Class> object. This is the metaclass for the
method's class.

=back

=head2 $metamethod->clone(%params)

This makes a shallow clone of the method object. In particular,
subroutine reference itself is shared between all clones of a given
method.

When a method is cloned, the original method object will be available
by calling C<original_method> on the clone.

=head2 $metamethod->body

This returns a reference to the method's subroutine.

=head2 $metamethod->name

This returns the method's name.

=head2 $metamethod->package_name

This returns the method's package name.

=head2 $metamethod->fully_qualified_name

This returns the method's fully qualified name (package name and
method name).

=head2 $metamethod->associated_metaclass

This returns the L<Class::MOP::Class> object for the method, if one
exists.

=head2 $metamethod->original_method

If this method object was created as a clone of some other method
object, this returns the object that was cloned.

=head2 $metamethod->original_name

This returns the method's original name, wherever it was first
defined.

If this method is a clone of a clone (of a clone, etc.), this method
returns the name from the I<first> method in the chain of clones.

=head2 $metamethod->original_package_name

This returns the method's original package name, wherever it was first
defined.

If this method is a clone of a clone (of a clone, etc.), this method
returns the package name from the I<first> method in the chain of
clones.

=head2 $metamethod->original_fully_qualified_name

This returns the method's original fully qualified name, wherever it
was first defined.

If this method is a clone of a clone (of a clone, etc.), this method
returns the fully qualified name from the I<first> method in the chain
of clones.

=head2 $metamethod->is_stub

Returns true if the method is just a stub:

  sub foo;

=head2 $metamethod->attach_to_class($metaclass)

Given a L<Class::MOP::Class> object, this method sets the associated
metaclass for the method. This will overwrite any existing associated
metaclass.

=head2 $metamethod->detach_from_class

Removes any associated metaclass object for the method.

=head2 $metamethod->execute(...)

This executes the method. Any arguments provided will be passed on to
the method itself.

=head2 Moose::Meta::Method->meta

This will return a L<Class::MOP::Class> instance for this class.

It should also be noted that L<Class::MOP> will actually bootstrap
this module by installing a number of attribute meta-objects into its
metaclass.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
