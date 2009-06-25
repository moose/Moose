#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
    use_ok('Moose::AttributeHelpers');
}

{
    package MyHomePage;
    use Moose;

    has 'counter' => (metaclass => 'Counter');
}

my $page = MyHomePage->new();
isa_ok($page, 'MyHomePage');

can_ok($page, $_) for qw[
    dec_counter
    inc_counter
    reset_counter
];

is($page->counter, 0, '... got the default value');

$page->inc_counter;
is($page->counter, 1, '... got the incremented value');

$page->inc_counter;
is($page->counter, 2, '... got the incremented value (again)');

$page->dec_counter;
is($page->counter, 1, '... got the decremented value');

$page->reset_counter;
is($page->counter, 0, '... got the original value');

# check the meta ..

my $counter = $page->meta->get_attribute('counter');
isa_ok($counter, 'Moose::AttributeHelpers::Counter');

is($counter->helper_type, 'Num', '... got the expected helper type');

is($counter->type_constraint->name, 'Num', '... got the expected default type constraint');

is_deeply($counter->provides, {
    inc   => 'inc_counter',
    dec   => 'dec_counter',
    reset => 'reset_counter',
    set   => 'set_counter',
}, '... got the right default provides methods');

