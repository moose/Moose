#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 2;
use Test::More;

BEGIN {
  use_ok('Test::Moose');
}

{
    package Foo;
    use Moose;
}

package main;

test_out("ok 1", "not ok 2");
test_fail(+2);
with_immutable {
    ok(Foo->meta->is_mutable);
} qw(Foo);

test_test('with_immutable');
