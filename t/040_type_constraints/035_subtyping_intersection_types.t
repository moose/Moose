#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

BEGIN {
    use_ok("Moose::Util::TypeConstraints");
}

lives_ok {
    subtype 'MyCollections' => as 'ArrayRef & Ref';
} '... created the subtype special okay';

{
    my $t = find_type_constraint('MyCollections');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'MyCollections', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint::Intersection');
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'ArrayRef&Ref', '... parent name is correct');

    ok($t->check([]), '... validated it correctly');
    ok(!$t->check(1), '... validated it correctly');
}

lives_ok {
    subtype 'MyCollectionsExtended' 
        => as 'ArrayRef&Ref'
        => where {
            if (ref($_) eq 'ARRAY') {
                return if scalar(@$_) < 2;
            }
            1;
        };
} '... created the subtype special okay';

{
    my $t = find_type_constraint('MyCollectionsExtended');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'MyCollectionsExtended', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint::Intersection');
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'ArrayRef&Ref', '... parent name is correct');

    ok(!$t->check([]), '... validated it correctly');
    ok($t->check([1, 2]), '... validated it correctly');    
    
    ok($t->check([ one => 1, two => 2 ]), '... validated it correctly');    
    
    ok(!$t->check(1), '... validated it correctly');
}


