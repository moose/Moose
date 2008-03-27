#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 41;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');
}

my $Str       = find_type_constraint('Str');
my $Undef     = find_type_constraint('Undef');
my $Item      = find_type_constraint('Item');
my $Value     = find_type_constraint('Value');
my $ClassName = find_type_constraint('ClassName');
my $Num       = find_type_constraint('Num');
my $Int       = find_type_constraint('Int');

for my $type ($Str, $Undef, $Item, $Value, $ClassName, $Num, $Int) {
    isa_ok($type, 'Moose::Meta::TypeConstraint');
}

my $Str_or_Undef = Moose::Meta::TypeConstraint::Union->new(type_constraints => [$Str, $Undef]);
my $Value_or_Undef = Moose::Meta::TypeConstraint::Union->new(type_constraints => [$Value, $Undef]);
my $Int_or_ClassName = Moose::Meta::TypeConstraint::Union->new(type_constraints => [$Int, $ClassName]);

for my $type ($Str_or_Undef, $Value_or_Undef, $Int_or_ClassName) {
    isa_ok($type, 'Moose::Meta::TypeConstraint::Union');
}

ok($Str_or_Undef->includes_type($Str), "Str | Undef includes Str");
ok($Str_or_Undef->includes_type($Undef), "Str | Undef includes Undef");
ok(!$Str_or_Undef->includes_type($Item), "Str | Undef doesn't include supertype Item");
ok(!$Str_or_Undef->includes_type($Value), "Str | Undef doesn't include supertype Value");
ok($Str_or_Undef->includes_type($ClassName), "Str | Undef includes Str subtype ClassName");
ok(!$Str_or_Undef->includes_type($Num), "Str | Undef doesn't include Num");
ok(!$Str_or_Undef->includes_type($Int), "Str | Undef doesn't include Int");
ok(!$Str_or_Undef->includes_type($Value_or_Undef), "Str | Undef doesn't include supertype Value | Undef");
ok($Str_or_Undef->includes_type($Str_or_Undef), "Str | Undef includes Str | Undef");
ok(!$Str_or_Undef->includes_type($Int_or_ClassName), "Str | Undef doesn't include Int | ClassName");

ok($Value_or_Undef->includes_type($Value), "Value | Undef includes Value");
ok($Value_or_Undef->includes_type($Undef), "Value | Undef includes Undef");
ok(!$Value_or_Undef->includes_type($Item), "Value | Undef doesn't include supertype Item");
ok($Value_or_Undef->includes_type($Str), "Value | Undef includes subtype Str");
ok($Value_or_Undef->includes_type($ClassName), "Value | Undef includes subtype ClassName");
ok($Value_or_Undef->includes_type($Num), "Value | Undef includes subtype Num");
ok($Value_or_Undef->includes_type($Int), "Value | Undef includes subtype Int");
ok($Value_or_Undef->includes_type($Str_or_Undef), "Value | Undef includes Str | Undef");
ok($Value_or_Undef->includes_type($Value_or_Undef), "Value | Undef includes Value | Undef");
ok($Value_or_Undef->includes_type($Int_or_ClassName), "Value | Undef includes Int | ClassName");

ok($Int_or_ClassName->includes_type($Int), "Int | ClassName includes Int");
ok($Int_or_ClassName->includes_type($ClassName), "Int | ClassName includes ClassName");
ok(!$Int_or_ClassName->includes_type($Str), "Int | ClassName doesn't include supertype Str");
ok(!$Int_or_ClassName->includes_type($Undef), "Int | ClassName doesn't include Undef");
ok(!$Int_or_ClassName->includes_type($Item), "Int | ClassName doesn't include supertype Item");
ok(!$Int_or_ClassName->includes_type($Value), "Int | ClassName doesn't include supertype Value");
ok(!$Int_or_ClassName->includes_type($Num), "Int | ClassName doesn't include supertype Num");
ok(!$Int_or_ClassName->includes_type($Str_or_Undef), "Int | ClassName doesn't include Str | Undef");
ok(!$Int_or_ClassName->includes_type($Value_or_Undef), "Int | ClassName doesn't include Value | Undef");
ok($Int_or_ClassName->includes_type($Int_or_ClassName), "Int | ClassName includes Int | ClassName");

