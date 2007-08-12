#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Moose::Util', ':all');
}

{
  package Foo;

  use Moose::Role;
}

{
  package Bar;

  use Moose;

  with qw/Foo/;
}

{
  package Baz;

  use Moose;
}

# Classes

ok(does_role('Bar', 'Foo'), '... Bar does Foo');

ok(!does_role('Baz', 'Foo'), '... Baz doesnt do Foo');

# Objects

my $bar = Bar->new;

ok(does_role($bar, 'Foo'), '... $bar does Foo');

my $baz = Baz->new;

ok(!does_role($baz, 'Foo'), '... $baz doesnt do Foo');

# Invalid values

ok(!does_role(undef,'Foo'), '... undef doesnt do Foo');

ok(!does_role(1,'Foo'), '... 1 doesnt do Foo');
