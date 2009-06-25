#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 50;
use Test::Exception;

BEGIN {
    use_ok('Moose::AttributeHelpers');
}

{
    package Stuff;
    use Moose;
    use Moose::AttributeHelpers;

    has 'options' => (
        metaclass => 'Collection::Hash',
        is        => 'ro',
        isa       => 'HashRef[Str]',
        default   => sub { {} },
        handles  => {
            'set_option'       => 'set',
            'get_option'       => 'get',
            'has_options'      => 'empty',
            'num_options'      => 'count',
            'clear_options'    => 'clear', 
            'delete_option'    => 'delete', 
            'has_option'       => 'exists',
            'is_defined'       => 'defined',
            'option_accessor'  => 'accessor',
            'key_value'        => 'kv', 
            'options_elements' => 'elements',
            'quantity' => [ accessor => ['quantity'] ],
        },
    );
}

my $stuff = Stuff->new();
isa_ok($stuff, 'Stuff');

can_ok($stuff, $_) for qw[
    set_option
    get_option
    has_options
    num_options
    delete_option
    clear_options
    is_defined
    has_option
    quantity
    option_accessor
];

ok(!$stuff->has_options, '... we have no options');
is($stuff->num_options, 0, '... we have no options');

is_deeply($stuff->options, {}, '... no options yet');
ok(!$stuff->has_option('foo'), '... we have no foo option');

lives_ok {
    $stuff->set_option(foo => 'bar');
} '... set the option okay';

ok($stuff->is_defined('foo'), '... foo is defined');

ok($stuff->has_options, '... we have options');
is($stuff->num_options, 1, '... we have 1 option(s)');
ok($stuff->has_option('foo'), '... we have a foo option');
is_deeply($stuff->options, { foo => 'bar' }, '... got options now');

lives_ok {
    $stuff->set_option(bar => 'baz');
} '... set the option okay';

is($stuff->num_options, 2, '... we have 2 option(s)');
is_deeply($stuff->options, { foo => 'bar', bar => 'baz' }, '... got more options now');

is($stuff->get_option('foo'), 'bar', '... got the right option');

is_deeply([ $stuff->get_option(qw(foo bar)) ], [qw(bar baz)], "get multiple options at once");

lives_ok {
    $stuff->set_option(oink => "blah", xxy => "flop");
} '... set the option okay';

is($stuff->num_options, 4, "4 options");
is_deeply([ $stuff->get_option(qw(foo bar oink xxy)) ], [qw(bar baz blah flop)], "get multiple options at once");

lives_ok {
    $stuff->delete_option('bar');
} '... deleted the option okay';

lives_ok {
    $stuff->delete_option('oink');
} '... deleted the option okay';

lives_ok {
    $stuff->delete_option('xxy');
} '... deleted the option okay';

is($stuff->num_options, 1, '... we have 1 option(s)');
is_deeply($stuff->options, { foo => 'bar' }, '... got more options now');

$stuff->clear_options;

is_deeply($stuff->options, { }, "... cleared options" );

lives_ok {
    $stuff->quantity(4);
} '... options added okay with defaults';

is($stuff->quantity, 4, 'reader part of curried accessor works');

is_deeply($stuff->options, {quantity => 4}, '... returns what we expect');

lives_ok {
    Stuff->new(options => { foo => 'BAR' });
} '... good constructor params';

## check some errors

dies_ok {
    $stuff->set_option(bar => {});
} '... could not add a hash ref where an string is expected';

dies_ok {
    Stuff->new(options => { foo => [] });
} '... bad constructor params';

dies_ok {
    my $stuff = Stuff->new;
    $stuff->option_accessor();
} '... accessor dies on 0 args';

dies_ok {
    my $stuff = Stuff->new;
    $stuff->option_accessor(1 => 2, 3);
} '... accessor dies on 3 args';

dies_ok {
    my $stuff = Stuff->new;
    $stuff->option_accessor(1 => 2, 3 => 4);
} '... accessor dies on 4 args';

## test the meta

my $options = $stuff->meta->get_attribute('options');
isa_ok($options, 'Moose::AttributeHelpers::Collection::Hash');

is_deeply($options->handles, {
   'add_options'           => 'push',
   'remove_last_option'    => 'pop',
   'remove_first_option'   => 'shift',
   'insert_options'        => 'unshift',
   'get_option_at'         => 'get',
   'set_option_at'         => 'set',
   'num_options'           => 'count',
   'has_options'           => 'empty',
   'clear_options'         => 'clear',
   'splice_options'        => 'splice',
   'sort_options_in_place' => 'sort_in_place',
   'option_accessor'       => 'accessor',
}, '... got the right handles mapping');

is($options->type_constraint->type_parameter, 'Str', '... got the right container type');

$stuff->set_option( oink => "blah", xxy => "flop" );
my @key_value = $stuff->key_value;
is_deeply(
    \@key_value,
    [ [ 'xxy', 'flop' ], [ 'quantity', 4 ], [ 'oink', 'blah' ] ],
    '... got the right key value pairs'
);

my %options_elements = $stuff->options_elements;
is_deeply(
    \%options_elements,
    {
        'oink'     => 'blah',
        'quantity' => 4,
        'xxy'      => 'flop'
    },
    '... got the right hash elements'
);
