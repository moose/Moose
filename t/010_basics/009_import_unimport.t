#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 46;


my @moose_exports = qw(
    extends with 
    has 
    before after around
    override
    augment
    super inner
    make_immutable
);

{
    package Foo;

    use Moose;
}

can_ok('Foo', $_) for @moose_exports;

{
    package Foo;
    no Moose;
}

ok(!Foo->can($_), '... Foo can no longer do ' . $_) for @moose_exports;

# and check the type constraints as well

my @moose_type_constraint_exports = qw(
    type subtype as where message 
    coerce from via 
    enum
    find_type_constraint
);

{
    package Bar;

    use Moose::Util::TypeConstraints;
}

can_ok('Bar', $_) for @moose_type_constraint_exports;

{
    package Bar;
    no Moose::Util::TypeConstraints;
}

ok(!Bar->can($_), '... Bar can no longer do ' . $_) for @moose_type_constraint_exports;

