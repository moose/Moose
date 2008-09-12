#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
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
