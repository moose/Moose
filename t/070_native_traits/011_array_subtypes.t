#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    use Moose::Util::TypeConstraints;
    use List::Util qw(sum);

    subtype 'A1', as 'ArrayRef[Int]';
    subtype 'A2', as 'ArrayRef', where { @$_ < 2 };
    subtype 'A3', as 'ArrayRef[Int]', where { ( sum(@$_) || 0 ) < 5 };

    no Moose::Util::TypeConstraints;
}

{
    package Foo;
    use Moose;

    has array => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef',
        handles => {
            push_array => 'push',
        },
    );
    has array_int => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef[Int]',
        handles => {
            push_array_int => 'push',
        },
    );
    has a1 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A1',
        handles => {
            push_a1 => 'push',
        },
    );
    has a2 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A2',
        handles => {
            push_a2 => 'push',
        },
    );
    has a3 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A3',
        handles => {
            push_a3 => 'push',
        },
    );
}

my $foo = Foo->new;

{
    $foo->array( [] );
    is_deeply( $foo->array, [], "array - correct contents" );

    $foo->push_array('foo');
    is_deeply( $foo->array, ['foo'], "array - correct contents" );
}

{
    $foo->array_int( [] );
    is_deeply( $foo->array_int, [], "array_int - correct contents" );

    dies_ok { $foo->push_array_int('foo') }
    "array_int - can't push wrong type";
    is_deeply( $foo->array_int, [], "array_int - correct contents" );

    $foo->push_array_int(1);
    is_deeply( $foo->array_int, [1], "array_int - correct contents" );
}

{
    dies_ok { $foo->push_a1('foo') } "a1 - can't push onto undef";

    $foo->a1( [] );
    is_deeply( $foo->a1, [], "a1 - correct contents" );

    dies_ok { $foo->push_a1('foo') } "a1 - can't push wrong type";

    is_deeply( $foo->a1, [], "a1 - correct contents" );

    $foo->push_a1(1);
    is_deeply( $foo->a1, [1], "a1 - correct contents" );
}

{
    dies_ok { $foo->push_a2('foo') } "a2 - can't push onto undef";

    $foo->a2( [] );
    is_deeply( $foo->a2, [], "a2 - correct contents" );

    $foo->push_a2('foo');
    is_deeply( $foo->a2, ['foo'], "a2 - correct contents" );

    dies_ok { $foo->push_a2('bar') } "a2 - can't push more than one element";

    is_deeply( $foo->a2, ['foo'], "a2 - correct contents" );
}

{
    dies_ok { $foo->push_a3(1) } "a3 - can't push onto undef";

    $foo->a3( [] );
    is_deeply( $foo->a3, [], "a3 - correct contents" );

    dies_ok { $foo->push_a3('foo') } "a3 - can't push non-int";

    dies_ok { $foo->push_a3(100) }
    "a3 - can't violate overall type constraint";

    is_deeply( $foo->a3, [], "a3 - correct contents" );

    $foo->push_a3(1);
    is_deeply( $foo->a3, [1], "a3 - correct contents" );

    dies_ok { $foo->push_a3(100) }
    "a3 - can't violate overall type constraint";

    is_deeply( $foo->a3, [1], "a3 - correct contents" );

    $foo->push_a3(3);
    is_deeply( $foo->a3, [ 1, 3 ], "a3 - correct contents" );
}

done_testing;
