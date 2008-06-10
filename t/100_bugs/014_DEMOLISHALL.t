#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;

our ($class_demolish, $child_demolish) = (0, 0);
our ($class_demolishall, $child_demolishall) = (0, 0);

do {
    package Class;
    use Moose;

    sub DEMOLISH {
        ++$::class_demolish;
    }

    sub DEMOLISHALL {
        my $self = shift;
        ++$::class_demolishall;
        $self->SUPER::DEMOLISHALL(@_);
    }

    package Child;
    use Moose;
    extends 'Class';

    sub DEMOLISH {
        ++$::child_demolish;
    }

    sub DEMOLISHALL {
        my $self = shift;
        ++$::child_demolishall;
        $self->SUPER::DEMOLISHALL(@_);
    }
};

is($class_demolish, 0, "no calls to Class->DEMOLISH");
is($child_demolish, 0, "no calls to Child->DEMOLISH");

is($class_demolishall, 0, "no calls to Class->DEMOLISHALL");
is($child_demolishall, 0, "no calls to Child->DEMOLISHALL");

do {
    my $object = Class->new;

    is($class_demolish, 0, "Class->new does not call Class->DEMOLISH");
    is($child_demolish, 0, "Class->new does not call Child->DEMOLISH");

    is($class_demolishall, 0, "Class->new does not call Class->DEMOLISHALL");
    is($child_demolishall, 0, "Class->new does not call Child->DEMOLISHALL");
};

is($class_demolish, 1, "Class->DESTROY calls Class->DEMOLISH");
is($child_demolish, 0, "Class->DESTROY does not call Child->DEMOLISH");

is($class_demolishall, 1, "Class->DESTROY calls Class->DEMOLISHALL");
is($child_demolishall, 0, "no calls to Child->DEMOLISHALL");

do {
    my $child = Child->new;

    is($class_demolish, 1, "Child->new does not call Class->DEMOLISH");
    is($child_demolish, 0, "Child->new does not call Child->DEMOLISH");

    is($class_demolishall, 1, "Child->DEMOLISHALL does not call Class->DEMOLISHALL (but not Child->new)");
    is($child_demolishall, 0, "Child->new does not call Child->DEMOLISHALL");
};

is($child_demolish, 1, "Child->DESTROY calls Child->DEMOLISH");
is($class_demolish, 2, "Child->DESTROY also calls Class->DEMOLISH");

is($child_demolishall, 1, "Child->DESTROY calls Child->DEMOLISHALL");
is($class_demolishall, 2, "Child->DEMOLISHALL calls Class->DEMOLISHALL (but not Child->DESTROY)");
