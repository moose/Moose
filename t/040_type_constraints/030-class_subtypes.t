#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');
    use_ok('Moose::Meta::TypeConstraint');           
}

## Create a subclass with a custom method

{
    package Test::Moose::Meta::TypeConstraint::AnySubType;
    use Moose;
    extends 'Moose::Meta::TypeConstraint';
    
    sub my_custom_method {
        return 1;
    }
}

my $Int = Moose::Util::TypeConstraints::find_type_constraint('Int');
ok $Int, 'Got a good type contstraint';

my $parent  = Test::Moose::Meta::TypeConstraint::AnySubType->new({
		name => "Test::Moose::Meta::TypeConstraint::AnySubType" ,
		parent => $Int,
});

ok $parent, 'Created type constraint';
ok $parent->check(1), 'Correctly passed';
ok ! $parent->check('a'), 'correctly failed';
ok $parent->my_custom_method, 'found the custom method';

my $subtype1 = Moose::Util::TypeConstraints::subtype 'another_subtype',
    as $parent;

ok $subtype1, 'Created type constraint';
ok $subtype1->check(1), 'Correctly passed';
ok ! $subtype1->check('a'), 'correctly failed';
ok $subtype1->my_custom_method, 'found the custom method';


my $subtype2 = Moose::Util::TypeConstraints::subtype 'another_subtype',
    as $subtype1,
    where { $_ < 10 };

ok $subtype2, 'Created type constraint';
ok $subtype2->check(1), 'Correctly passed';
ok ! $subtype2->check('a'), 'correctly failed';
ok ! $subtype2->check(100), 'correctly failed';

ok $subtype2->my_custom_method, 'found the custom method';