#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

BEGIN {
    use_ok('Moose::AttributeHelpers');
}

{
    package Stuff;
    use Moose;
    use Moose::AttributeHelpers;

    has 'word_histogram' => (
        metaclass => 'Collection::Bag',
        is        => 'ro',
        provides  => {
            'add'    => 'add_word',
            'get'    => 'get_count_for',
            'empty'  => 'has_any_words',
            'count'  => 'num_words',
            'delete' => 'delete_word',
        }
    );
}

my $stuff = Stuff->new();
isa_ok($stuff, 'Stuff');

can_ok($stuff, $_) for qw[
    add_word
    get_count_for
    has_any_words
    num_words
    delete_word
];

ok(!$stuff->has_any_words, '... we have no words');
is($stuff->num_words, 0, '... we have no words');

lives_ok {
    $stuff->add_word('bar');
} '... set the words okay';

ok($stuff->has_any_words, '... we have words');
is($stuff->num_words, 1, '... we have 1 word(s)');
is($stuff->get_count_for('bar'), 1, '... got words now');

lives_ok {
    $stuff->add_word('foo');
    $stuff->add_word('bar') for 0 .. 3;
    $stuff->add_word('baz') for 0 .. 10;
} '... set the words okay';

is($stuff->num_words, 3, '... we still have 1 word(s)');
is($stuff->get_count_for('foo'), 1, '... got words now');
is($stuff->get_count_for('bar'), 5, '... got words now');
is($stuff->get_count_for('baz'), 11, '... got words now');

## test the meta

my $words = $stuff->meta->get_attribute('word_histogram');
isa_ok($words, 'Moose::AttributeHelpers::Collection::Bag');

is_deeply($words->provides, {
    'add'    => 'add_word',
    'get'    => 'get_count_for',
    'empty'  => 'has_any_words',
    'count'  => 'num_words',
    'delete' => 'delete_word',
}, '... got the right provides mapping');

