#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Moose');
}

{
    package Foo;
    use Moose;
    sub foo { 'foo' }

    package Bar;
    use Moose;
    sub foo { 'bar' }

    package FooBar;
    use Moose;
    extends 'Foo';
    around foo => sub{ shift->(@_) };
}

FooBar->meta->superclasses('Bar');
is(FooBar->foo, 'bar', 'method modified changed along with metaclass');
