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

    make_immutable;
}

is(blessed(Grandparent->new), "Grandparent", "got a Grandparent object out of Grandparent->new");
is(blessed(Parent->new), "Parent", "got a Parent object out of Parent->new");
is(blessed(Child->new), "Child", "got a Child object out of Child->new");

is(Child->new->grandparent, 1, "Child responds to grandparent");
is(Child->new->parent, 1, "Child responds to parent");
is(Child->new->child, 1, "Child responds to child");

is(Child->new->{grandparent}, 'gramma', "Instance structure has attributes");
is(Child->new->{parent}, 'mama', "Parent's 'around' is respected");

