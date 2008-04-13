#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Util::TypeConstraints');
}

my $type = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Maybe[Int]');
isa_ok($type, 'Moose::Meta::TypeConstraint');
isa_ok($type, 'Moose::Meta::TypeConstraint::Parameterized');

ok( $type->equals($type), "equals self" );
ok( !$type->equals($type->parent), "not equal to parent" );
ok( !$type->equals(find_type_constraint("Maybe")), "not equal to Maybe" );
ok( $type->parent->equals(find_type_constraint("Maybe")), "parent is Maybe" );
ok( $type->equals( Moose::Meta::TypeConstraint::Parameterized->new( name => "__ANON__", parent => find_type_constraint("Maybe"), type_parameter => find_type_constraint("Int") ) ), "equal to clone" );
ok( !$type->equals( Moose::Meta::TypeConstraint::Parameterized->new( name => "__ANON__", parent => find_type_constraint("Maybe"), type_parameter => find_type_constraint("Str") ) ), "not equal to clone with diff param" );
ok( !$type->equals( Moose::Util::TypeConstraints::find_or_parse_type_constraint('Maybe[Str]') ), "not equal to declarative version of diff param" );

ok($type->check(10), '... checked type correctly (pass)');
ok($type->check(undef), '... checked type correctly (pass)');
ok(!$type->check('Hello World'), '... checked type correctly (fail)');
ok(!$type->check([]), '... checked type correctly (fail)');

{
    package Foo;
    use Moose;
    
    has 'bar' => (is => 'rw', isa => 'Maybe[ArrayRef]', required => 1);    
}

lives_ok {
    Foo->new(bar => []);
} '... it worked!';

lives_ok {
    Foo->new(bar => undef);
} '... it worked!';

dies_ok {
    Foo->new(bar => 100);
} '... failed the type check';

dies_ok {
    Foo->new(bar => 'hello world');
} '... failed the type check';

