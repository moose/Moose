use strict;
use warnings;
use Test::More;

use Test::Requires 'Moo', 'Test::Warnings';
use Test::Warnings qw( warnings :no_end_test );

{
    package Foo;

    use Moo;

    has foo => (
        is      => 'ro',
        handles => ['bar'],
    );
}

{
    package Bar;

    use Moose;

    ::is_deeply(
        [ ::warnings { extends 'Foo' } ],
        [],
        'no warnings when extending Moo class that has a delegation'
    );
}

done_testing();
