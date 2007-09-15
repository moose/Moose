#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');           
}

my $Str = find_type_constraint('Str');
isa_ok($Str, 'Moose::Meta::TypeConstraint');

my $Undef = find_type_constraint('Undef');
isa_ok($Undef, 'Moose::Meta::TypeConstraint');

ok(!$Str->check(undef), '... Str cannot accept an Undef value');
ok($Str->check('String'), '... Str can accept an String value');
ok(!$Undef->check('String'), '... Undef cannot accept an Str value');
ok($Undef->check(undef), '... Undef can accept an Undef value');

my $Str_or_Undef = Moose::Meta::TypeConstraint::Union->new(type_constraints => [$Str, $Undef]);
isa_ok($Str_or_Undef, 'Moose::Meta::TypeConstraint::Union');

ok($Str_or_Undef->check(undef), '... (Str | Undef) can accept an Undef value');
ok($Str_or_Undef->check('String'), '... (Str | Undef) can accept a String value');

# another ....

my $ArrayRef = find_type_constraint('ArrayRef');
isa_ok($ArrayRef, 'Moose::Meta::TypeConstraint');

my $HashRef = find_type_constraint('HashRef');
isa_ok($HashRef, 'Moose::Meta::TypeConstraint');

ok($ArrayRef->check([]), '... ArrayRef can accept an [] value');
ok(!$ArrayRef->check({}), '... ArrayRef cannot accept an {} value');
ok($HashRef->check({}), '... HashRef can accept an {} value');
ok(!$HashRef->check([]), '... HashRef cannot accept an [] value');

my $HashOrArray = Moose::Meta::TypeConstraint::Union->new(type_constraints => [$ArrayRef, $HashRef]);
isa_ok($HashOrArray, 'Moose::Meta::TypeConstraint::Union');

ok($HashOrArray->check([]), '... (ArrayRef | HashRef) can accept []');
ok($HashOrArray->check({}), '... (ArrayRef | HashRef) can accept {}');

ok(!$HashOrArray->check(\(my $var1)), '... (ArrayRef | HashRef) cannot accept scalar refs');
ok(!$HashOrArray->check(sub {}), '... (ArrayRef | HashRef) cannot accept code refs');
ok(!$HashOrArray->check(50), '... (ArrayRef | HashRef) cannot accept Numbers');

diag $HashOrArray->validate([]);

ok(!defined($HashOrArray->validate([])), '... (ArrayRef | HashRef) can accept []');
ok(!defined($HashOrArray->validate({})), '... (ArrayRef | HashRef) can accept {}');

is($HashOrArray->validate(\(my $var2)), 'Validation failed for \'ArrayRef\' failed and Validation failed for \'HashRef\' failed in (ArrayRef | HashRef)', '... (ArrayRef | HashRef) cannot accept scalar refs');
is($HashOrArray->validate(sub {}),      'Validation failed for \'ArrayRef\' failed and Validation failed for \'HashRef\' failed in (ArrayRef | HashRef)', '... (ArrayRef | HashRef) cannot accept code refs');
is($HashOrArray->validate(50),          'Validation failed for \'ArrayRef\' failed and Validation failed for \'HashRef\' failed in (ArrayRef | HashRef)', '... (ArrayRef | HashRef) cannot accept Numbers');

