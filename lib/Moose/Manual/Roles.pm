=pod

=head1 NAME

Moose::Manual::Roles - Roles, an Alternative to Deep Hierarchies and Base Classes

=head1 WHAT IS A ROLE?

A role is something that classes do. Usually, a role encapsulates some
piece of behavior or state that can be shared between classes. It is
important to understand that I<roles are not classes>. Roles do not
participate in inheritance, and a role cannot be instantiated.

Instead, a role is I<composed> into a class. In practical terms, this
means that all of the methods and attributes defined in a role are
added directly to (we sometimes say ("flattened into") the class that
consumes the role. These attributes and methods then show up in the
class as if they were defined directly in the class.

Moose roles are similar to mixins or interfaces in other languages.

Besides defining their own methods and attributes, roles can also
require that the consuming class define certain methods of its
own. You could have a role that consisted only of a list of required
methods, in which case the role would be very much like a Java
interface.

=head1 A SIMPLE ROLE

Creating a role looks a lot like creating a Moose class:

  package Breakable;

  use Moose::Role;

  has 'is_broken' => (
      is  => 'rw',
      isa => 'Bool',
  );

  sub break {
      my $self = shift;

      print "I broke\n";

      $self->is_broken(1);
  }

Except for our use of C<Moose::Role>, this looks just like a class
definition with Moose. However, this is not a class, and it cannot be
instantiated.

Instead, its attributes and methods will be composed into classes
which use the role:

  package Car;

  use Moose;

  with 'Breakable';

  has 'engine' => (
      is  => 'ro',
      isa => 'Engine',
  );

The C<with> function composes roles into a class. Once that is done,
the C<Car> class has an C<is_broken> attribute and a C<break>
method. The C<Car> class also C<does('Breakable')>:

  my $car = Car->new( engine => Engine->new() );

  print $car->is_broken() ? 'Still working' : 'Busted';
  $car->break();
  print $car->is_broken() ? 'Still working' : 'Busted';

  $car->does('Breakable'); # true

This prints:

  Still working
  I broke
  Busted

We could use this same role in a C<Bone> class:

  package Bone;

  use Moose;

  with 'Breakable';

  has 'marrow' => (
      is  => 'ro',
      isa => 'Marrow',
  );

=head1 REQUIRED METHODS

As mentioned previously, a role can require that consuming classes
provide one or more methods. Using our C<Breakable> example, let's
make it require that consuming classes implement their own C<break>
methods:

  package Breakable;

  use Moose::Role;

  requires 'break';

  has 'is_broken' => (
      is  => 'rw',
      isa => 'Bool',
  );

  after 'break' => sub {
      my $self = shift;

      $self->is_broken(1);
  }

If we try to consume this role in a class that does not have a
C<break> method, we will get an exception.

Note that attribute-generated accessors do not satisfy the requirement
that the named method exists. Similarly, a method modifier does not
satisfy this requirement either. This may change in the future.

You can also see that we added a method modifier on
C<break>. Basically, we want consuming classes to implement their own
logic for breaking, but we make sure that the C<is_broken> attribute
is always set to true when C<break> is called.

  package Car

  use Moose;

  with 'Breakable';

  has 'engine' => (
      is  => 'ro',
      isa => 'Engine',
  );

  sub break {
      my $self = shift;

      if ( $self->is_moving() ) {
          $self->stop();
      }
  }

=head1 USING METHOD MODIFIERS

Method modifiers and roles are a very powerful combination.  Often, a
role will combine method modifiers and required methods. We already
saw one example with our C<Breakable> example.

Once caveat to be aware of with method modifiers in roles is that they
introduce an ordering issue to role application.

