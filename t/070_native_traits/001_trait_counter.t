#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose 'does_ok';

my %handles = (
    inc_counter    => 'inc',
    inc_counter_2  => [ inc => 2 ],
    dec_counter    => 'dec',
    dec_counter_2  => [ dec => 2 ],
    reset_counter  => 'reset',
    set_counter    => 'set',
    set_counter_42 => [ set => 42 ],
);

{
    package MyHomePage;
    use Moose;

    has 'counter' => (
        traits  => ['Counter'],
        is      => 'ro',
        isa     => 'Int',
        default => 0,
        handles => \%handles,
    );
}

my $page = MyHomePage->new();
isa_ok( $page, 'MyHomePage' );

can_ok( $page, $_ ) for sort keys %handles;

is( $page->counter, 0, '... got the default value' );

$page->inc_counter;
is( $page->counter, 1, '... got the incremented value' );

$page->inc_counter;
is( $page->counter, 2, '... got the incremented value (again)' );

$page->dec_counter;
is( $page->counter, 1, '... got the decremented value' );

$page->reset_counter;
is( $page->counter, 0, '... got the original value' );

$page->set_counter(5);
is( $page->counter, 5, '... set the value' );

$page->inc_counter(2);
is( $page->counter, 7, '... increment by arg' );

$page->dec_counter(5);
is( $page->counter, 2, '... decrement by arg' );

$page->inc_counter_2;
is( $page->counter, 4, '... curried increment' );

$page->dec_counter_2;
is( $page->counter, 2, '... curried deccrement' );

$page->set_counter_42;
is( $page->counter, 42, '... curried set' );

done_testing;
