#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 52;
use Test::Exception;

use Scalar::Util ();

use Moose::Util::TypeConstraints;


type Number => where { Scalar::Util::looks_like_number($_) };
type String 
    => where { !ref($_) && !Number($_) }
    => message { "This is not a string ($_)" };

subtype Natural 
        => as Number 
        => where { $_ > 0 };

subtype NaturalLessThanTen 
        => as Natural
        => where { $_ < 10 }
        => message { "The number '$_' is not less than 10" };
        
Moose::Util::TypeConstraints->export_type_constraints_as_functions();

ok(Number(5), '... this is a Num');
ok(!defined(Number('Foo')), '... this is not a Num');
{
    my $number_tc = Moose::Util::TypeConstraints::find_type_constraint('Number');
    is("$number_tc", 'Number', '... type constraint stringifies to name');
}

ok(String('Foo'), '... this is a Str');
ok(!defined(String(5)), '... this is not a Str');

ok(Natural(5), '... this is a Natural');
is(Natural(-5), undef, '... this is not a Natural');
is(Natural('Foo'), undef, '... this is not a Natural');

ok(NaturalLessThanTen(5), '... this is a NaturalLessThanTen');
is(NaturalLessThanTen(12), undef, '... this is not a NaturalLessThanTen');
is(NaturalLessThanTen(-5), undef, '... this is not a NaturalLessThanTen');
is(NaturalLessThanTen('Foo'), undef, '... this is not a NaturalLessThanTen');
        
# anon sub-typing       
        
my $negative = subtype Number => where  { $_ < 0 };
ok(defined $negative, '... got a value back from negative');
isa_ok($negative, 'Moose::Meta::TypeConstraint');

ok($negative->check(-5), '... this is a negative number');
ok(!defined($negative->check(5)), '... this is not a negative number');
is($negative->check('Foo'), undef, '... this is not a negative number');

ok($negative->is_subtype_of('Number'), '... $negative is a subtype of Number');
ok(!$negative->is_subtype_of('String'), '... $negative is not a subtype of String');

my $negative2 = subtype Number => where { $_ < 0 } => message {"$_ is not a negative number"};

ok(defined $negative2, '... got a value back from negative');
isa_ok($negative2, 'Moose::Meta::TypeConstraint');

ok($negative2->check(-5), '... this is a negative number');
ok(!defined($negative2->check(5)), '... this is not a negative number');
is($negative2->check('Foo'), undef, '... this is not a negative number');

ok($negative2->is_subtype_of('Number'), '... $negative2 is a subtype of Number');
ok(!$negative2->is_subtype_of('String'), '... $negative is not a subtype of String');

ok($negative2->has_message, '... it has a message');
is($negative2->validate(2), 
   '2 is not a negative number',
   '... validated unsuccessfully (got error)');

# check some meta-details

my $natural_less_than_ten = find_type_constraint('NaturalLessThanTen');
isa_ok($natural_less_than_ten, 'Moose::Meta::TypeConstraint');

ok($natural_less_than_ten->is_subtype_of('Natural'), '... NaturalLessThanTen is subtype of Natural');
ok($natural_less_than_ten->is_subtype_of('Number'), '... NaturalLessThanTen is subtype of Number');
ok(!$natural_less_than_ten->is_subtype_of('String'), '... NaturalLessThanTen is not subtype of String');

ok($natural_less_than_ten->has_message, '... it has a message');

ok(!defined($natural_less_than_ten->validate(5)), '... validated successfully (no error)');

is($natural_less_than_ten->validate(15), 
   "The number '15' is not less than 10", 
   '... validated unsuccessfully (got error)');

my $natural = find_type_constraint('Natural');
isa_ok($natural, 'Moose::Meta::TypeConstraint');

ok($natural->is_subtype_of('Number'), '... Natural is a subtype of Number');
ok(!$natural->is_subtype_of('String'), '... Natural is not a subtype of String');

ok(!$natural->has_message, '... it does not have a message');

ok(!defined($natural->validate(5)), '... validated successfully (no error)');

is($natural->validate(-5), 
  "Validation failed for 'Natural' failed with value -5", 
  '... validated unsuccessfully (got error)');

my $string = find_type_constraint('String');
isa_ok($string, 'Moose::Meta::TypeConstraint');

ok($string->has_message, '... it does have a message');

ok(!defined($string->validate("Five")), '... validated successfully (no error)');

is($string->validate(5), 
"This is not a string (5)", 
'... validated unsuccessfully (got error)');

lives_ok { Moose::Meta::Attribute->new('bob', isa => 'Spong') }
  'meta-attr construction ok even when type constraint utils loaded first';

# Test type constraint predicate return values.

foreach my $predicate (qw/equals is_subtype_of is_a_type_of/) {
    ok( !defined $string->$predicate('DoesNotExist'), "$predicate predicate returns undef for non existant constraint");
}

# Test adding things which don't look like types to the registry throws an exception

my $r = Moose::Util::TypeConstraints->get_type_constraint_registry;
throws_ok {$r->add_type_constraint()} qr/not a valid type constraint/, '->add_type_constraint(undef) throws';
throws_ok {$r->add_type_constraint('foo')} qr/not a valid type constraint/, '->add_type_constraint("foo") throws';
throws_ok {$r->add_type_constraint(bless {}, 'SomeClass')} qr/not a valid type constraint/, '->add_type_constraint(SomeClass->new) throws';

