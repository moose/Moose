#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;

BEGIN {
    use_ok('Moose');           
}

my @moose_exports = qw(
    extends with 
    has 
    before after around
    override super
    augment inner
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