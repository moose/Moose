#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use Scalar::Util 'blessed';

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Meta::Role');
}

=pod

This test it kind of odd, it tests 
to see if make_immutable will DWIM 
when pressented with a class that 
inherits from a non-Moose base class.

Since immutable only affects the local
class, and if it doesnt find a constructor
it will always create one, it won't 
discover this issue, and it will ignore
the inherited constructor.

This is not really the desired way, but
detecting this opens a big can of worms
which we are not going to deal with just 
yet (eventually yes, but most likely it
will be when we have MooseX::Compile
available and working). 

In the meantime, just know that when you 
call make_immutable on a class which 
inherits from a non-Moose class, you 
should add (inline_constructor => 0).

Sorry Sartak.

=cut

{
    package Grandparent;

    sub new {
        my $class = shift;
        my %args  = (
            grandparent => 'gramma',
            @_,
        );

        bless \%args => $class;
    }

    sub grandparent { 1 }
}

{
    package Parent;
    use Moose;
    extends 'Grandparent';

    around new => sub {
        my $orig  = shift;
        my $class = shift;

        $class->$orig(
            parent => 'mama',
            @_,
        );
    };

    sub parent { 1 }
}

{
    package Child;
    use Moose;
    extends 'Parent';

    sub child { 1 }

    __PACKAGE__->meta->make_immutable;
}

is(blessed(Grandparent->new), "Grandparent", "got a Grandparent object out of Grandparent->new");
is(blessed(Parent->new), "Parent", "got a Parent object out of Parent->new");
is(blessed(Child->new), "Child", "got a Child object out of Child->new");

is(Child->new->grandparent, 1, "Child responds to grandparent");
is(Child->new->parent, 1, "Child responds to parent");
is(Child->new->child, 1, "Child responds to child");

is(Child->new->{grandparent}, undef, "didnt create a value, cause immutable overode the constructor");
is(Child->new->{parent}, undef, "didnt create a value, cause immutable overode the constructor");


