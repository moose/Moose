#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

BEGIN {
    use_ok("Moose::Util::TypeConstraints");
    use_ok('Moose::Meta::TypeConstraint::Parameterized');
}

lives_ok {
    subtype 'AlphaKeyHash' => as 'HashRef'
        => where {
            # no keys match non-alpha
            (grep { /[^a-zA-Z]/ } keys %$_) == 0
        };
} '... created the subtype special okay';

lives_ok {
    subtype 'Trihash' => as 'AlphaKeyHash'
        => where {
            keys(%$_) == 3
        };
} '... created the subtype special okay';

lives_ok {
    subtype 'Noncon' => as 'Item';
} '... created the subtype special okay';

{
    my $t = find_type_constraint('AlphaKeyHash');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'AlphaKeyHash', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'HashRef', '... parent name is correct');

    ok($t->check({ one => 1, two => 2 }), '... validated it correctly');
    ok(!$t->check({ one1 => 1, two2 => 2 }), '... validated it correctly');
}

my $hoi = Moose::Util::TypeConstraints::find_or_create_type_constraint('AlphaKeyHash[Int]');

ok($hoi->check({ one => 1, two => 2 }), '... validated it correctly');
ok(!$hoi->check({ one1 => 1, two2 => 2 }), '... validated it correctly');
ok(!$hoi->check({ one => 'uno', two => 'dos' }), '... validated it correctly');
ok(!$hoi->check({ one1 => 'un', two2 => 'deux' }), '... validated it correctly');

my $th = Moose::Util::TypeConstraints::find_or_create_type_constraint('Trihash[Bool]');

ok(!$th->check({ one => 1, two => 1 }), '... validated it correctly');
ok($th->check({ one => 1, two => 0, three => 1 }), '... validated it correctly');
ok(!$th->check({ one => 1, two => 2, three => 1 }), '... validated it correctly');
ok(!$th->check({foo1 => 1, bar2 => 0, baz3 => 1}), '... validated it correctly');

dies_ok {
    Moose::Meta::TypeConstraint::Parameterized->new(
        name           => 'Str[Int]',
        parent         => find_type_constraint('Str'),
        type_parameter => find_type_constraint('Int'),
    );
} 'non-containers cannot be parameterized';

dies_ok {
    Moose::Meta::TypeConstraint::Parameterized->new(
        name           => 'Noncon[Int]',
        parent         => find_type_constraint('Noncon'),
        type_parameter => find_type_constraint('Int'),
    );
} 'non-containers cannot be parameterized';

