#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

my ($destroyed, $demolished);
{
    package Foo;

    sub new { bless {}, shift }

    sub DESTROY { $destroyed++ }
}

{
    package Foo::Sub;
    use Moose;

    extends 'Foo';

    sub DEMOLISH { $demolished++ }
}

with_immutable {
    ($destroyed, $demolished) = (0, 0);
    { Foo::Sub->new }
    is($destroyed, 1, "non-Moose destructor called");
    is($demolished, 1, "Moose destructor called");
} 'Foo::Sub';

done_testing;
