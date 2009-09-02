#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Moose;

{
    package MyHomePage;
    use Moose;

    has 'counter' => ( traits => ['Counter'] );
}

my $page = MyHomePage->new();
isa_ok( $page, 'MyHomePage' );

can_ok( $page, $_ ) for qw[
    dec_counter
    inc_counter
    reset_counter
];

is( $page->counter, 0, '... got the default value' );

$page->inc_counter;
is( $page->counter, 1, '... got the incremented value' );

$page->inc_counter;
is( $page->counter, 2, '... got the incremented value (again)' );

$page->dec_counter;
is( $page->counter, 1, '... got the decremented value' );

$page->reset_counter;
is( $page->counter, 0, '... got the original value' );

# check the meta ..

my $counter = $page->meta->get_attribute('counter');
does_ok( $counter, 'Moose::Meta::Attribute::Native::Trait::Counter' );

is( $counter->type_constraint->name, 'Num',
    '... got the expected default type constraint' );

is_deeply(
    $counter->handles,
    {
        'inc_counter'   => 'inc',
        'dec_counter'   => 'dec',
        'reset_counter' => 'reset',
        'set_counter'   => 'set',
    },
    '... got the right default handles methods'
);

