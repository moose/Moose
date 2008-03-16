#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 47;

BEGIN {
    use_ok('Moose');           
}

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
}

eval q{
    package Foo;
    use Moose;
};
ok(!$@, '... Moose succesfully exported into Foo');

can_ok('Foo', $_) for @moose_exports;

eval q{
    package Foo;
    no Moose;
};
ok(!$@, '... Moose succesfully un-exported from Foo');

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
}

eval q{
    package Bar;
    use Moose::Util::TypeConstraints;
};
ok(!$@, '... Moose::Util::TypeConstraints succesfully exported into Bar');

can_ok('Bar', $_) for @moose_type_constraint_exports;

eval q{
    package Bar;
    no Moose::Util::TypeConstraints;
};
ok(!$@, '... Moose::Util::TypeConstraints succesfully un-exported from Bar');

ok(!Bar->can($_), '... Bar can no longer do ' . $_) for @moose_type_constraint_exports;

