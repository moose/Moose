use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Moose;

{
    package Foo;
    use Moose;
}

{
    package Bar;
    use Moose;
}

{
    my @expect = split /\n/, <<'EOF';
    # Subtest: Foo is not immutable
    ok 1
    1..1
ok 1 - Foo is not immutable
    # Subtest: Foo is immutable
    not ok 1
    1..1
not ok 2 - Foo is immutable
EOF

    test_out(@expect);
    test_fail(+4);
    my $ret = with_immutable {
        ok( Foo->meta->is_mutable );
    }
    qw(Foo);
    test_test('with_immutable failure');
    ok( !$ret, 'one of our tests failed' );
}

{
    my @expect = split /\n/, <<'EOF';
    # Subtest: Bar is not immutable
    ok 1
    1..1
ok 1 - Bar is not immutable
    # Subtest: Bar is immutable
    ok 1
    1..1
ok 2 - Bar is immutable
EOF

    test_out(@expect);
    my $ret = with_immutable {
        ok( Bar->meta->find_method_by_name('new') );
    }
    qw(Bar);
    test_test('with_immutable success');
    ok( $ret, "all tests succeeded" );
}

done_testing;
