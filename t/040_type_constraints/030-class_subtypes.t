#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;

use Moose::Util::TypeConstraints;
use Moose::Meta::TypeConstraint;


## Create a subclass with a custom method

{
    package Test::Moose::Meta::TypeConstraint::AnySubType;
    use Moose;
    extends 'Moose::Meta::TypeConstraint';
    
    sub my_custom_method {
        return 1;
    }
}

my $Int = find_type_constraint('Int');
ok $Int, 'Got a good type contstraint';

my $parent  = Test::Moose::Meta::TypeConstraint::AnySubType->new({
		name => "Test::Moose::Meta::TypeConstraint::AnySubType" ,
		parent => $Int,
});

ok $parent, 'Created type constraint';
ok $parent->check(1), 'Correctly passed';
ok ! $parent->check('a'), 'correctly failed';
ok $parent->my_custom_method, 'found the custom method';

my $subtype1 = subtype 'another_subtype' => as $parent;

ok $subtype1, 'Created type constraint';
ok $subtype1->check(1), 'Correctly passed';
ok ! $subtype1->check('a'), 'correctly failed';
ok $subtype1->my_custom_method, 'found the custom method';


my $subtype2 = subtype 'another_subtype' => as $subtype1 => where { $_ < 10 };

ok $subtype2, 'Created type constraint';
ok $subtype2->check(1), 'Correctly passed';
ok ! $subtype2->check('a'), 'correctly failed';
ok ! $subtype2->check(100), 'correctly failed';

ok $subtype2->my_custom_method, 'found the custom method';


{
    package Foo;

    use Moose;
}

{
    package Bar;

    use Moose;

    extends 'Foo';
}

{
    package Baz;

    use Moose;
}

my $foo = class_type 'Foo';
my $isa_foo = subtype 'IsaFoo' => as $foo;

ok $isa_foo, 'Created subtype of Foo type';
ok $isa_foo->check( Foo->new ), 'Foo passes check';
ok $isa_foo->check( Bar->new ), 'Bar passes check';
ok ! $isa_foo->check( Baz->new ), 'Baz does not pass check';
