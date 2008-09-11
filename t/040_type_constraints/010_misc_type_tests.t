#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');           
}

# subtype 'aliasing' ...

lives_ok {
    subtype 'Numb3rs' => as 'Num';
} '... create bare subtype fine';

my $numb3rs = find_type_constraint('Numb3rs');
isa_ok($numb3rs, 'Moose::Meta::TypeConstraint');

# subtype with unions

{
    package Test::Moose::Meta::TypeConstraint::Union;

    use overload '""' => sub {'Broken|Test'}, fallback => 1;
    use Moose;

    extends 'Moose::Meta::TypeConstraint';
}

my $dummy_instance = Test::Moose::Meta::TypeConstraint::Union->new;

ok $dummy_instance => "Created Instance";

isa_ok $dummy_instance,
    'Test::Moose::Meta::TypeConstraint::Union' => 'isa correct type';

is "$dummy_instance", "Broken|Test" =>
    'Got expected stringification result';

my $subtype1 = subtype 'New1' => as $dummy_instance;

ok $subtype1 => 'made a subtype from our type object';

my $subtype2 = subtype 'New2' => as $subtype1;

ok $subtype2 => 'made a subtype of our subtype';

# testing the parameterize method

{
	my $parameterizable = subtype 'parameterizable_hashref',
		as 'HashRef';
		
	my $parameterized = subtype 'parameterized_hashref',
		as 'HashRef[Int]';
		
	my $int = Moose::Util::TypeConstraints::find_type_constraint('Int');
		
	my $from_parameterizable = $parameterizable->parameterize($int);
	
	isa_ok $parameterizable, 'Moose::Meta::TypeConstraint::Parameterizable',
	 => 'Got expected type instance';

	package Test::Moose::Meta::TypeConstraint::Parameterizable;
	use Moose;
	
	has parameterizable => (is=>'rw', isa=>$parameterizable);
	has parameterized => (is=>'rw', isa=>$parameterized);
	has from_parameterizable => (is=>'rw', isa=>$from_parameterizable);
}

# Create and check a dummy object

ok my $params = Test::Moose::Meta::TypeConstraint::Parameterizable->new()
 => 'Create Dummy object for testing';
 
isa_ok $params, 'Test::Moose::Meta::TypeConstraint::Parameterizable'
 => 'isa correct type';

# test parameterizable

lives_ok sub {
	$params->parameterizable({a=>'Hello', b=>'World'});
} => 'No problem setting parameterizable';

is_deeply $params->parameterizable, {a=>'Hello', b=>'World'}
 => 'Got expected values';

# test parameterized

lives_ok sub {
	$params->parameterized({a=>1, b=>2});
} => 'No problem setting parameterized';

is_deeply $params->parameterized, {a=>1, b=>2}
 => 'Got expected values';
 
throws_ok sub {
	$params->parameterized({a=>'Hello', b=>'World'});
}, qr/Attribute \(parameterized\) does not pass the type constraint/
 => 'parameterized throws expected error';

# test from_parameterizable

lives_ok sub {
	$params->from_parameterizable({a=>1, b=>2});
} => 'No problem setting from_parameterizable';

is_deeply $params->from_parameterizable, {a=>1, b=>2}
 => 'Got expected values';
 
throws_ok sub {
	$params->from_parameterizable({a=>'Hello', b=>'World'});
}, qr/Attribute \(from_parameterizable\) does not pass the type constraint/
 => 'from_parameterizable throws expected error';
 
 
 
 
 
 
 