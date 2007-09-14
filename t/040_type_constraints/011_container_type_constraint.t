#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
    use_ok('Moose::Util::TypeConstraints');               
    use_ok('Moose::Meta::TypeConstraint::Container');               
}

# Array of Ints

my $array_of_ints = Moose::Meta::TypeConstraint::Container->new(
    name           => 'ArrayRef[Int]',
    parent         => find_type_constraint('ArrayRef'),
    container_type => find_type_constraint('Int'),
);
isa_ok($array_of_ints, 'Moose::Meta::TypeConstraint::Container');
isa_ok($array_of_ints, 'Moose::Meta::TypeConstraint');

ok($array_of_ints->check([ 1, 2, 3, 4 ]), '... [ 1, 2, 3, 4 ] passed successfully');
ok(!$array_of_ints->check([qw/foo bar baz/]), '... [qw/foo bar baz/] failed successfully');
ok(!$array_of_ints->check([ 1, 2, 3, qw/foo bar/]), '... [ 1, 2, 3, qw/foo bar/] failed successfully');

ok(!$array_of_ints->check(1), '... 1 failed successfully');
ok(!$array_of_ints->check({}), '... {} failed successfully');
ok(!$array_of_ints->check(sub { () }), '... sub { () } failed successfully');

# Hash of Ints

my $hash_of_ints = Moose::Meta::TypeConstraint::Container->new(
    name           => 'HashRef[Int]',
    parent         => find_type_constraint('HashRef'),
    container_type => find_type_constraint('Int'),
);
isa_ok($hash_of_ints, 'Moose::Meta::TypeConstraint::Container');
isa_ok($hash_of_ints, 'Moose::Meta::TypeConstraint');

ok($hash_of_ints->check({ one => 1, two => 2, three => 3 }), '... { one => 1, two => 2, three => 3 } passed successfully');
ok(!$hash_of_ints->check({ 1 => 'one', 2 => 'two', 3 => 'three' }), '... { 1 => one, 2 => two, 3 => three } failed successfully');
ok(!$hash_of_ints->check({ 1 => 'one', 2 => 'two', three => 3 }), '... { 1 => one, 2 => two, three => 3 } failed successfully');

ok(!$hash_of_ints->check(1), '... 1 failed successfully');
ok(!$hash_of_ints->check([]), '... [] failed successfully');
ok(!$hash_of_ints->check(sub { () }), '... sub { () } failed successfully');

# Array of Array of Ints

my $array_of_array_of_ints = Moose::Meta::TypeConstraint::Container->new(
    name           => 'ArrayRef[ArrayRef[Int]]',
    parent         => find_type_constraint('ArrayRef'),
    container_type => $array_of_ints,
);
isa_ok($array_of_array_of_ints, 'Moose::Meta::TypeConstraint::Container');
isa_ok($array_of_array_of_ints, 'Moose::Meta::TypeConstraint');

ok($array_of_array_of_ints->check(
    [[ 1, 2, 3 ], [ 4, 5, 6 ]]
), '... [[ 1, 2, 3 ], [ 4, 5, 6 ]] passed successfully');
ok(!$array_of_array_of_ints->check(
    [[ 1, 2, 3 ], [ qw/foo bar/ ]]
), '... [[ 1, 2, 3 ], [ qw/foo bar/ ]] failed successfully');

