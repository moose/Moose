#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');
}

{
    package Gorch;
    use Moose::Role;

    package Bar;
    use Moose::Role;

    package Foo;
    use Moose::Role;

    with qw(Bar Gorch);

    package FooC;
    use Moose;
    with qw(Foo);

    package BarC;
    use Moose;
    with qw(Bar);

}

lives_ok { role_type('Boop', message { "${_} is not a Boop" }) }
  'role_type keywork works with message';

my $type = find_type_constraint("Foo");

is( $type->role, "Foo", "role attribute" );

ok( $type->is_subtype_of("Gorch"), "subtype of gorch" );

ok( $type->is_subtype_of("Bar"), "subtype of bar" );

ok( $type->is_subtype_of("Object"), "subtype of Object" );
ok( $type->is_subtype_of("Role"), "subtype of Role" );

ok( !$type->is_subtype_of("ThisTypeDoesNotExist"), "not subtype of unknown type name" );
ok( !$type->is_a_type_of("ThisTypeDoesNotExist"), "not type of unknown type name" );

ok( find_type_constraint("Bar")->check(FooC->new), "Foo passes Bar" );
ok( find_type_constraint("Bar")->check(BarC->new), "Bar passes Bar" );
ok( !find_type_constraint("Gorch")->check(BarC->new), "but Bar doesn't pass Gorch");

my $boop = find_type_constraint("Boop");
ok( $boop->has_message, 'Boop has a message');
my $error = $boop->get_message(FooC->new);
like( $error, qr/is not a Boop/,  'boop gives correct error message');


ok( $type->equals($type), "equals self" );
ok( $type->equals(Moose::Meta::TypeConstraint::Role->new( name => "__ANON__", role => "Foo" )), "equals anon constraint of same value" );
ok( $type->equals(Moose::Meta::TypeConstraint::Role->new( name => "Oink", role => "Foo" )), "equals differently named constraint of same value" );
ok( !$type->equals(Moose::Meta::TypeConstraint::Role->new( name => "__ANON__", role => "Bar" )), "doesn't equal other anon constraint" );
ok( $type->is_subtype_of(Moose::Meta::TypeConstraint::Role->new( name => "__ANON__", role => "Bar" )), "subtype of other anon constraint" );

