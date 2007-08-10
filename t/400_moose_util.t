#!/usr/bin/env perl

use Test::More tests => 13;

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

#
#   search_class_by_role tests
#
BEGIN { Moose::Util->import(qw( search_class_by_role )) }
my $t_pfx = 'search_class_by_role: ';

{   package SCBR::Role;
    use Moose::Role;
}

{   package SCBR::A;
    use Moose;
}
is search_class_by_role('SCBR::A', 'SCBR::Role'), undef, $t_pfx . 'not found role returns undef';

{   package SCBR::B;
    use Moose;
    extends 'SCBR::A';
    with 'SCBR::Role';
}
is search_class_by_role('SCBR::B', 'SCBR::Role'), 'SCBR::B', $t_pfx . 'class itself returned if it does role';

{   package SCBR::C;
    use Moose;
    extends 'SCBR::B';
}
is search_class_by_role('SCBR::C', 'SCBR::Role'), 'SCBR::B', $t_pfx . 'nearest class doing role returned';

{   package SCBR::D;
    use Moose;
    extends 'SCBR::C';
    with 'SCBR::Role';
}
is search_class_by_role('SCBR::D', 'SCBR::Role'), 'SCBR::D', $t_pfx . 'nearest class being direct class returned';

