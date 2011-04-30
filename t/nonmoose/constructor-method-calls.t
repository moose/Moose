#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

my ($foo, $foosub);
{
    package Foo;

    sub new {
        my $class = shift;
        my $obj = bless {}, $class;
        $obj->init;
        $obj;
    }

    sub init {
        $foo++
    }
}

{
    package Foo::Sub;
    use base 'Foo';

    sub init {
        $foosub++;
        shift->SUPER::init;
    }
}

{
    package Foo::Sub::Sub;
    use Moose;

    extends 'Foo::Sub';
}

with_immutable {
    ($foo, $foosub) = (0, 0);
    Foo::Sub::Sub->new;
    is($foo, 1, "Foo::init called");
    is($foosub, 1, "Foo::Sub::init called");
} 'Foo::Sub::Sub';

done_testing;
