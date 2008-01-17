#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Util::TypeConstraints');
}

my $type = Moose::Util::TypeConstraints::find_or_create_type_constraint('Maybe[Int]');
isa_ok($type, 'Moose::Meta::TypeConstraint');
isa_ok($type, 'Moose::Meta::TypeConstraint::Parameterized');

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

