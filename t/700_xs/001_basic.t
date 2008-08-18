#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    plan skip_all => "no XSLoader" unless eval { require XSLoader };

    plan skip_all => $@ unless eval {
        require Moose;
        Moose->XSLoader::load($Moose::VERSION);
        1;
    };

    plan 'no_plan';
}

ok( defined &Moose::XS::install_simple_getter );
ok( defined &Moose::XS::install_simple_setter );
ok( defined &Moose::XS::install_simple_accessor );
ok( defined &Moose::XS::install_predicate );

{
    package Foo;
    use Moose;

    has x => ( is => "rw", predicate => "has_x" );
    has y => ( is => "ro" );
    has z => ( reader => "z", setter => "set_z" );
}

Moose::XS::install_simple_accessor("Foo::x", "x");
Moose::XS::install_predicate("Foo::has_x", "x");
Moose::XS::install_simple_getter("Foo::y", "y");
Moose::XS::install_simple_getter("Foo::z", "z");
Moose::XS::install_simple_setter("Foo::set_z", "z");

my $foo = Foo->new( x => "ICKS", y => "WHY", z => "ZEE" );

is( $foo->x, "ICKS" );
is( $foo->y, "WHY" );
is( $foo->z, "ZEE" );

lives_ok { $foo->x("YASE") };

is( $foo->x, "YASE" );

dies_ok { $foo->y("blah") };

is( $foo->y, "WHY" );

dies_ok { $foo->z("blah") };

is( $foo->z, "ZEE" );

lives_ok { $foo->set_z("new") };

is( $foo->z, "new" );

ok( $foo->has_x );

ok( !Foo->new->has_x );

