#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');           
}

{
    package Gorch;
    use Moose;

    package Bar;
    use Moose;

    package Foo;
    use Moose;

    extends qw(Bar Gorch);
}

my $type = find_type_constraint("Foo");

ok( $type->is_subtype_of("Gorch"), "subtype of gorch" );

ok( $type->is_subtype_of("Bar"), "subtype of bar" );

ok( $type->is_subtype_of("Object"), "subtype of Object" );

ok( find_type_constraint("Bar")->check(Foo->new), "Foo passes Bar" );
ok( find_type_constraint("Bar")->check(Bar->new), "Bar passes Bar" );
ok( !find_type_constraint("Gorch")->check(Bar->new), "but Bar doesn't pass Gorch");

