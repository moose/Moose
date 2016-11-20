use strict;
use warnings;

use Test::More;

use Test::Requires 'Test::Output';

my $file = __FILE__;

{
    package Bar;
    use Moose;

    has has_attr => (
        is => 'ro',
    );

    ::stderr_like(
        sub {
            has attr => (
                is        => 'ro',
                predicate => 'has_attr',
            );
        },
        qr/
           \QYou are overwriting a reader (has_attr) for the has_attr attribute\E
           \Q (defined at $file line \E\d+\)
           \Q with a new predicate method for the attr attribute\E
           \Q (defined at $file line \E\d+\)
          /x,
        'overwriting an accessor for another attribute causes a warning'
    );
}

{
    package Foo;
    use Moose;

    ::stderr_like(
        sub {
            has buz => (
                reader => 'my_buz',
                writer => 'my_buz',
            );
        },
        qr/
           \QYou are overwriting a reader (my_buz) for the buz attribute\E
           \Q (defined at $file line \E\d+\)
           \Q with a new writer method for the buz attribute\E
           \Q (defined at $file line \E\d+\)
          /x,
        'overwriting an accessor for the same attribute causes a warning'
    );
}

done_testing;
