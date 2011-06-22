#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');
}

my $Str = find_type_constraint('Str');
isa_ok($Str, 'Moose::Meta::TypeConstraint');

my $Defined = find_type_constraint('Defined');
isa_ok($Defined, 'Moose::Meta::TypeConstraint');

ok(!$Str->check(undef), '... Str cannot accept an Undef value');
ok($Str->check('String'), '... Str can accept an String value');
ok($Defined->check('String'), '... Defined can accept an Str value');
ok(!$Defined->check(undef), '... Defined cannot accept an undef value');

my $Str_and_Defined = Moose::Meta::TypeConstraint::Intersection->new(type_constraints => [$Str, $Defined]);
isa_ok($Str_and_Defined, 'Moose::Meta::TypeConstraint::Intersection');

ok($Str_and_Defined->check(''), '... (Str & Defined) can accept a Defined value');
ok($Str_and_Defined->check('String'), '... (Str & Defined) can accept a String value');
ok(!$Str_and_Defined->check([]), '... (Str & Defined) cannot accept an array reference');

ok($Str_and_Defined->is_a_type_of($Str), "subtype of Str");
ok($Str_and_Defined->is_a_type_of($Defined), "subtype of Defined");

ok( !$Str_and_Defined->equals($Str), "not equal to Str" );
ok( $Str_and_Defined->equals($Str_and_Defined), "equal to self" );
ok( $Str_and_Defined->equals(Moose::Meta::TypeConstraint::Intersection->new(type_constraints => [ $Str, $Defined ])), "equal to clone" );
ok( $Str_and_Defined->equals(Moose::Meta::TypeConstraint::Intersection->new(type_constraints => [ $Defined, $Str ])), "equal to reversed clone" );

ok( !$Str_and_Defined->is_a_type_of("ThisTypeDoesNotExist"), "not type of non existant type" );
ok( !$Str_and_Defined->is_subtype_of("ThisTypeDoesNotExist"), "not subtype of non existant type" );

# another ....

my $ArrayRef = find_type_constraint('ArrayRef');
isa_ok($ArrayRef, 'Moose::Meta::TypeConstraint');

my $Ref = find_type_constraint('Ref');
isa_ok($Ref, 'Moose::Meta::TypeConstraint');

ok($ArrayRef->check([]), '... ArrayRef can accept an [] value');
ok(!$ArrayRef->check({}), '... ArrayRef cannot accept an {} value');
ok($Ref->check({}), '... Ref can accept an {} value');
ok(!$Ref->check(5), '... Ref cannot accept a 5 value');

my $RefAndArray = Moose::Meta::TypeConstraint::Intersection->new(type_constraints => [$ArrayRef, $Ref]);
isa_ok($RefAndArray, 'Moose::Meta::TypeConstraint::Intersection');

ok($RefAndArray->check([]), '... (ArrayRef & Ref) can accept []');
ok(!$RefAndArray->check({}), '... (ArrayRef & Ref) cannot accept {}');

ok(!$RefAndArray->check(\(my $var1)), '... (ArrayRef & Ref) cannot accept scalar refs');
ok(!$RefAndArray->check(sub {}), '... (ArrayRef & Ref) cannot accept code refs');
ok(!$RefAndArray->check(50), '... (ArrayRef & Ref) cannot accept Numbers');

diag $RefAndArray->validate([]);

ok(!defined($RefAndArray->validate([])), '... (ArrayRef & Ref) can accept []');
ok(defined($RefAndArray->validate(undef)), '... (ArrayRef & Ref) cannot accept undef');

like($RefAndArray->validate(undef),
qr/Validation failed for \'ArrayRef\' with value undef and Validation failed for \'Ref\' with value undef in \(ArrayRef&Ref\)/,
'... (ArrayRef & Ref) cannot accept undef');

