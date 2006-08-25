#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;

BEGIN {
    use_ok('Moose');           
}

my @moose_exports = qw(
    extends with 
    has 
    before after around
    override
    augment
    method
);

my @moose_not_unimported = qw(
    super inner self
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
can_ok('Foo', $_) for @moose_not_unimported;

eval q{
    package Foo;
    no Moose;
};
ok(!$@, '... Moose succesfully un-exported from Foo');

ok(!Foo->can($_), '... Foo can no longer do ' . $_) for @moose_exports;
can_ok('Foo', $_) for @moose_not_unimported;

