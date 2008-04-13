#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
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

}

lives_ok { role_type 'Beep' } 'role_type keywork works';
lives_ok { role_type('Boop', message { "${_} is not a Boop" }) }
  'role_type keywork works with message';

my $type = find_type_constraint("Foo");

is( $type->role, "Foo", "role attribute" );

ok( $type->is_subtype_of("Gorch"), "subtype of gorch" );

ok( $type->is_subtype_of("Bar"), "subtype of bar" );

ok( $type->is_subtype_of("Object"), "subtype of Object" );

ok( find_type_constraint("Bar")->check(Foo->new), "Foo passes Bar" );
ok( find_type_constraint("Bar")->check(Bar->new), "Bar passes Bar" );
ok( !find_type_constraint("Gorch")->check(Bar->new), "but Bar doesn't pass Gorch");

ok( find_type_constraint("Beep")->check( bless {} => 'Beep' ), "Beep passes Beep" );
my $boop = find_type_constraint("Boop");
ok( $boop->has_message, 'Boop has a message');
my $error = $boop->get_message(Foo->new);
like( $error, qr/is not a Boop/,  'boop gives correct error message');


ok( $type->equals($type), "equals self" );
ok( $type->equals(Moose::Meta::TypeConstraint::Role->new( name => "__ANON__", role => "Foo" )), "equals anon constraint of same value" );
ok( $type->equals(Moose::Meta::TypeConstraint::Role->new( name => "Oink", role => "Foo" )), "equals differently named constraint of same value" );
ok( !$type->equals(Moose::Meta::TypeConstraint::Role->new( name => "__ANON__", role => "Bar" )), "doesn't equal other anon constraint" );
ok( $type->is_subtype_of(Moose::Meta::TypeConstraint::Role->new( name => "__ANON__", role => "Bar" )), "subtype of other anon constraint" );

