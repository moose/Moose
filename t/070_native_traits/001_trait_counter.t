#!/usr/bin/perl

use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::Moose;

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

    package Foo;
    use Moose;

    has 'counter' => (
        traits  => ['Counter'],
        is      => 'ro',
        isa     => 'Int',
        default => 0,
        handles => \%handles,
    );
}

can_ok( 'Foo', $_ ) for sort keys %handles;

with_immutable {
    my $page = Foo->new();

    is( $page->counter, 0, '... got the default value' );

    $page->inc_counter;
    is( $page->counter, 1, '... got the incremented value' );

    $page->inc_counter;
    is( $page->counter, 2, '... got the incremented value (again)' );

    throws_ok { $page->inc_counter( 1, 2 ) }
    qr/Cannot call inc with more than 1 argument/,
        'inc throws an error when two arguments are passed';

    $page->dec_counter;
    is( $page->counter, 1, '... got the decremented value' );

    throws_ok { $page->dec_counter( 1, 2 ) }
    qr/Cannot call dec with more than 1 argument/,
        'dec throws an error when two arguments are passed';

    $page->reset_counter;
    is( $page->counter, 0, '... got the original value' );

    throws_ok { $page->reset_counter(2) }
    qr/Cannot call reset with any arguments/,
        'reset throws an error when an argument is passed';

    $page->set_counter(5);
    is( $page->counter, 5, '... set the value' );

    throws_ok { $page->set_counter( 1, 2 ) }
    qr/Cannot call set with more than 1 argument/,
        'set throws an error when two arguments are passed';

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
}
'Foo';

done_testing;
