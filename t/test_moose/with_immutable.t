use strict;
use warnings;

use Test::Requires {
    'Test::Stream::Tester' => 0,
    'Test::Builder '       => '1.0302007',
};

use Test::Stream::Tester;
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
    events_are(
        intercept {
            with_immutable {
                ok( Foo->meta->is_mutable );
            }
            'Foo';
        },
        events {
            event 'Subtest' => sub {
                event_call diag      => [qr/Foo is not immutable/];
                event_call subevents => events {
                    event Ok => sub {
                        event_call pass => 1;
                    };
                    event Plan => { max => 1 };
                };
            };
            event 'Subtest' => sub {
                event_call diag      => [qr/Foo is immutable/];
                event_call subevents => events {
                    event Ok => sub {
                        event_call pass => 0;
                    };
                    event Plan => { max => 1 };
                };
            };
            event Plan => { max => 2 };
        },
    );
}


#     my @expect = split /\n/, <<'EOF';
#     # Subtest: Foo is not immutable
#     ok 1
#     1..1
# ok 1 - Foo is not immutable
#     # Subtest: Foo is immutable
#     not ok 1
#     1..1
# not ok 2 - Foo is immutable
# EOF

#     test_out(@expect);
#     test_fail(+4);
#     my $ret = with_immutable {
#         ok( Foo->meta->is_mutable );
#     }
#     qw(Foo);
#     test_test('with_immutable failure');
#     ok( !$ret, 'one of our tests failed' );
# }

# {
#     my @expect = split /\n/, <<'EOF';
#     # Subtest: Bar is not immutable
#     ok 1
#     1..1
# ok 1 - Bar is not immutable
#     # Subtest: Bar is immutable
#     ok 1
#     1..1
# ok 2 - Bar is immutable
# EOF

#     test_out(@expect);
#     my $ret = with_immutable {
#         ok( Bar->meta->find_method_by_name('new') );
#     }
#     qw(Bar);
#     test_test('with_immutable success');
#     ok( $ret, "all tests succeeded" );
# }

done_testing;
