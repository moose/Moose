#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    use Moose::Util::TypeConstraints;
    use List::Util qw( sum );

    subtype 'H1', as 'HashRef[Int]';
    subtype 'H2', as 'HashRef', where { scalar keys %{$_} < 2 };
    subtype 'H3', as 'HashRef[Int]',
        where { ( sum( values %{$_} ) || 0 ) < 5 };

    no Moose::Util::TypeConstraints;
}

{

    package Foo;
    use Moose;

    has hash_int => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'HashRef[Int]',
        handles => {
            set_hash_int => 'set',
        },
    );

    has h1 => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'H1',
        handles => {
            set_h1 => 'set',
        },
    );

    has h2 => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'H2',
        handles => {
            set_h2 => 'set',
        },
    );

    has h3 => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'H3',
        handles => {
            set_h3 => 'set',
        },
    );
}

my $foo = Foo->new;

{
    $foo->hash_int( {} );
    is_deeply( $foo->hash_int, {}, "hash_int - correct contents" );

    dies_ok { $foo->set_hash_int( x => 'foo' ) }
    "hash_int - can't set wrong type";
    is_deeply( $foo->hash_int, {}, "hash_int - correct contents" );

    $foo->set_hash_int( x => 1 );
    is_deeply( $foo->hash_int, { x => 1 }, "hash_int - correct contents" );
}

{
    dies_ok { $foo->set_h1('foo') } "h1 - can't set onto undef";

    $foo->h1( {} );
    is_deeply( $foo->h1, {}, "h1 - correct contents" );

    dies_ok { $foo->set_h1( x => 'foo' ) } "h1 - can't set wrong type";

    is_deeply( $foo->h1, {}, "h1 - correct contents" );

    $foo->set_h1( x => 1 );
    is_deeply( $foo->h1, { x => 1 }, "h1 - correct contents" );
}

{
    dies_ok { $foo->set_h2('foo') } "h2 - can't set onto undef";

    $foo->h2( {} );
    is_deeply( $foo->h2, {}, "h2 - correct contents" );

    $foo->set_h2( x => 'foo' );
    is_deeply( $foo->h2, { x => 'foo' }, "h2 - correct contents" );

    dies_ok { $foo->set_h2( y => 'bar' ) }
    "h2 - can't set more than one element";

    is_deeply( $foo->h2, { x => 'foo' }, "h2 - correct contents" );
}

{
    dies_ok { $foo->set_h3(1) } "h3 - can't set onto undef";

    $foo->h3( {} );
    is_deeply( $foo->h3, {}, "h3 - correct contents" );

    dies_ok { $foo->set_h3( x => 'foo' ) } "h3 - can't set non-int";

    dies_ok { $foo->set_h3( x => 100 ) }
    "h3 - can't violate overall type constraint";

    is_deeply( $foo->h3, {}, "h3 - correct contents" );

    $foo->set_h3( x => 1 );
    is_deeply( $foo->h3, { x => 1 }, "h3 - correct contents" );

    dies_ok { $foo->set_h3( x => 100 ) }
    "h3 - can't violate overall type constraint";

    is_deeply( $foo->h3, { x => 1 }, "h3 - correct contents" );

    $foo->set_h3( y => 3 );
    is_deeply( $foo->h3, { x => 1, y => 3 }, "h3 - correct contents" );
}

done_testing;
