#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;
use Test::Exception;

BEGIN {
    use_ok("Moose::Util::TypeConstraints");
}

lives_ok {
    subtype 'MySpecialHash' => as 'HashRef[Int]';
} '... created the subtype special okay';

{
    my $t = find_type_constraint('MySpecialHash');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'MySpecialHash', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint::Parameterized');
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'HashRef[Int]', '... parent name is correct');

    ok($t->check({ one => 1, two => 2 }), '... validated it correctly');
    ok(!$t->check({ one => "ONE", two => "TWO" }), '... validated it correctly');

    ok( $t->equals($t), "equals to self" );
    ok( !$t->equals( $t->parent ), "not equal to parent" );
    ok( $t->parent->equals( $t->parent ), "parent equals to self" );
}

lives_ok {
    subtype 'MySpecialHashExtended' 
        => as 'HashRef[Int]'
        => where {
            # all values are less then 10
            (scalar grep { $_ < 10 } values %{$_}) ? 1 : undef
        };
} '... created the subtype special okay';

{
    my $t = find_type_constraint('MySpecialHashExtended');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'MySpecialHashExtended', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint::Parameterized');
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'HashRef[Int]', '... parent name is correct');

    ok($t->check({ one => 1, two => 2 }), '... validated it correctly');
    ok(!$t->check({ zero => 10, one => 11, two => 12 }), '... validated it correctly');
    ok(!$t->check({ one => "ONE", two => "TWO" }), '... validated it correctly');
}

lives_ok {
    subtype 'MyNonSpecialHash'
        => as "HashRef"
        => where { keys %$_ == 3 };
};

{
    my $t = find_type_constraint('MyNonSpecialHash');

    isa_ok($t, 'Moose::Meta::TypeConstraint');
    isa_ok($t, 'Moose::Meta::TypeConstraint::Parameterizable');

    ok( $t->check({ one => 1, two => "foo", three => [] }), "validated" );
    ok( !$t->check({ one => 1 }), "failed" );
}

{
    my $t = Moose::Util::TypeConstraints::find_or_parse_type_constraint('MyNonSpecialHash[Int]');

    isa_ok($t, 'Moose::Meta::TypeConstraint');

    ok( $t->check({ one => 1, two => 2, three => 3 }), "validated" );
    ok( !$t->check({ one => 1, two => "foo", three => [] }), "failed" );
    ok( !$t->check({ one => 1 }), "failed" );
}
