#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

This tests how well Moose type constraints
play with Test::Deep.

Its not as pretty as Declare::Constraints::Simple,
but it is not completely horrid either.

=cut

use Test::Requires {
    'Test::Deep' => '0.01', # skip all if not installed
};

use Test::Exception;

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    use Test::Deep qw[
        eq_deeply array_each subhashof ignore
    ];

    # define your own type ...
    type 'ArrayOfHashOfBarsAndRandomNumbers'
        => where {
            eq_deeply($_,
                array_each(
                    subhashof({
                        bar           => Test::Deep::isa('Bar'),
                        random_number => ignore()
                    })
                )
            )
        };

    has 'bar' => (
        is  => 'rw',
        isa => 'ArrayOfHashOfBarsAndRandomNumbers',
    );

    package Bar;
    use Moose;
}

my $array_of_hashes = [
    { bar => Bar->new, random_number => 10 },
    { bar => Bar->new },
];

my $foo;
lives_ok {
    $foo = Foo->new('bar' => $array_of_hashes);
} '... construction succeeded';
isa_ok($foo, 'Foo');

is_deeply($foo->bar, $array_of_hashes, '... got our value correctly');

dies_ok {
    $foo->bar({});
} '... validation failed correctly';

dies_ok {
    $foo->bar([{ foo => 3 }]);
} '... validation failed correctly';

done_testing;
