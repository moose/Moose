#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;

use Scalar::Util ();

BEGIN {
    use_ok('Moose::Util::TypeConstraints');           
}

type Num => where { Scalar::Util::looks_like_number($_) };
type String => where { !ref($_) && !Num($_) };

subtype Natural 
	=> as Num 
	=> where { $_ > 0 };

subtype NaturalLessThanTen 
	=> as Natural
	=> where { $_ < 10 }
	=> message { "The number '$_' is not less than 10" };
	
Moose::Util::TypeConstraints->export_type_contstraints_as_functions();

is(Num(5), 5, '... this is a Num');
ok(!defined(Num('Foo')), '... this is not a Num');

is(String('Foo'), 'Foo', '... this is a Str');
ok(!defined(String(5)), '... this is not a Str');

is(Natural(5), 5, '... this is a Natural');
is(Natural(-5), undef, '... this is not a Natural');
is(Natural('Foo'), undef, '... this is not a Natural');

is(NaturalLessThanTen(5), 5, '... this is a NaturalLessThanTen');
is(NaturalLessThanTen(12), undef, '... this is not a NaturalLessThanTen');
is(NaturalLessThanTen(-5), undef, '... this is not a NaturalLessThanTen');
is(NaturalLessThanTen('Foo'), undef, '... this is not a NaturalLessThanTen');
	
# anon sub-typing	
	
my $negative = subtype Num => where	{ $_ < 0 };
ok(defined $negative, '... got a value back from negative');
isa_ok($negative, 'Moose::Meta::TypeConstraint');

is($negative->check(-5), -5, '... this is a negative number');
ok(!defined($negative->check(5)), '... this is not a negative number');
is($negative->check('Foo'), undef, '... this is not a negative number');

# check some meta-details

my $natural_less_than_ten = find_type_constraint('NaturalLessThanTen');
isa_ok($natural_less_than_ten, 'Moose::Meta::TypeConstraint');

ok($natural_less_than_ten->has_message, '... it has a message');

ok(!defined($natural_less_than_ten->validate(5)), '... validated successfully (no error)');

is($natural_less_than_ten->validate(15), 
   "The number '15' is not less than 10", 
   '... validated unsuccessfully (got error)');

my $natural = find_type_constraint('Natural');
isa_ok($natural, 'Moose::Meta::TypeConstraint');

ok(!$natural->has_message, '... it does not have a message');

ok(!defined($natural->validate(5)), '... validated successfully (no error)');

is($natural->validate(-5), 
  "Validation failed for 'Natural' failed.", 
  '... validated unsuccessfully (got error)');


