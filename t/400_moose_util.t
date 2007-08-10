#!/usr/bin/env perl

use Test::More tests => 9;

use strict;
use warnings;

BEGIN {
  use_ok('Moose');
  use_ok('Moose::Role');
  use_ok('Moose::Util');
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

ok(Moose::Util::does_role('Bar', 'Foo'));

ok(! Moose::Util::does_role('Baz', 'Foo'));

# Objects

my $bar = Bar->new;

ok(Moose::Util::does_role($bar, 'Foo'));

my $baz = Baz->new;

ok(! Moose::Util::does_role($baz, 'Foo'));

# Invalid values

ok(! Moose::Util::does_role(undef,'Foo'));

ok(! Moose::Util::does_role(1,'Foo'));

