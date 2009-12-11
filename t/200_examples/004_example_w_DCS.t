#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

This tests how well Moose type constraints
play with Declare::Constraints::Simple.

Pretty well if I do say so myself :)

=cut

BEGIN {
    eval "use Declare::Constraints::Simple;";
    plan skip_all => "Declare::Constraints::Simple is required for this test" if $@;
}

use Test::Exception;

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    use Declare::Constraints::Simple -All;

    # define your own type ...
    type( 'HashOfArrayOfObjects',
        {
        where => IsHashRef(
            -keys   => HasLength,
            -values => IsArrayRef(IsObject)
        )
    } );

    has 'bar' => (
        is  => 'rw',
        isa => 'HashOfArrayOfObjects',
    );

    # inline the constraints as anon-subtypes
    has 'baz' => (
        is  => 'rw',
        isa => subtype( { as => 'ArrayRef', where => IsArrayRef(IsInt) } ),
    );

    package Bar;
    use Moose;
}

my $hash_of_arrays_of_objs = {
   foo1 => [ Bar->new ],
   foo2 => [ Bar->new, Bar->new ],
};

my $array_of_ints = [ 1 .. 10 ];

my $foo;
lives_ok {
    $foo = Foo->new(
       'bar' => $hash_of_arrays_of_objs,
       'baz' => $array_of_ints,
    );
} '... construction succeeded';
isa_ok($foo, 'Foo');

is_deeply($foo->bar, $hash_of_arrays_of_objs, '... got our value correctly');
is_deeply($foo->baz, $array_of_ints, '... got our value correctly');

dies_ok {
    $foo->bar([]);
} '... validation failed correctly';

dies_ok {
    $foo->bar({ foo => 3 });
} '... validation failed correctly';

dies_ok {
    $foo->bar({ foo => [ 1, 2, 3 ] });
} '... validation failed correctly';

dies_ok {
    $foo->baz([ "foo" ]);
} '... validation failed correctly';

dies_ok {
    $foo->baz({});
} '... validation failed correctly';

done_testing;
