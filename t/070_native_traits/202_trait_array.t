#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 119;
use Test::Exception;
use Test::Moose 'does_ok';

my ($sort_in_place, $sort, $less, $up, $prod);
{

    package Stuff;
    use Moose;

    has 'options' => (
        traits  => ['Array'],
        is      => 'ro',
        isa     => 'ArrayRef[Str]',
        default => sub { [] },
        handles => {
            'add_options'           => 'push',
            'remove_last_option'    => 'pop',
            'remove_first_option'   => 'shift',
            'remove_option_at'      => 'delete',
            'insert_options'        => 'unshift',
            'insert_option_at'      => 'insert',
            'get_option_at'         => 'get',
            'set_option_at'         => 'set',
            'num_options'           => 'count',
            'has_no_options'        => 'is_empty',
            'clear_options'         => 'clear',
            'splice_options'        => 'splice',
            'sort_options_in_place' => 'sort_in_place',
            'option_accessor'       => 'accessor',
            'add_options_with_speed' =>
                [ 'push' => 'funrolls', 'funbuns' ],
            'prepend_prerequisites_along_with' =>
                [ 'unshift' => 'first', 'second' ],
            'descending_options' =>
                [ 'sort_in_place' => ($sort_in_place = sub { $_[1] <=> $_[0] }) ],
            'map_options',         => 'map',
            'filter_options'       => 'grep',
            'find_option'          => 'first',
            'join_options'         => 'join',
            'sorted_options'       => 'sort',
            'randomized_options'   => 'shuffle',
            'unique_options'       => 'uniq',
            'less_than_five'       => [ grep => ($less = sub { $_ < 5 }) ],
            'up_by_one'            => [ map => ($up = sub { $_ + 1 }) ],
            'pairwise_options'     => [ natatime => 2 ],
            'dashify'    => [ join => '-' ],
            'descending' => [ sort => ($sort = sub { $_[1] <=> $_[0] }) ],
            'product'    => [ reduce => ($prod = sub { $_[0] * $_[1] }) ],
        }
    );
}

my $stuff = Stuff->new( options => [ 10, 12 ] );
isa_ok( $stuff, 'Stuff' );

can_ok( $stuff, $_ ) for qw[
    add_options
    remove_last_option
    remove_first_option
    remove_option_at
    insert_options
    insert_option_at
    get_option_at
    set_option_at
    num_options
    has_no_options
    clear_options
    splice_options
    sort_options_in_place
    option_accessor
    add_options_with_speed
    prepend_prerequisites_along_with
    descending_options
    map_options
    filter_options
    find_option
    join_options
    sorted_options
    randomized_options
    unique_options
    less_than_five
    up_by_one
    pairwise_options
    dashify
    descending
    product
];

is_deeply( $stuff->options, [ 10, 12 ], 'got options' );

ok( !$stuff->has_no_options, 'we have options' );
is( $stuff->num_options, 2, 'got 2 options' );

is( $stuff->join_options(':'), '10:12', 'join returned the correct string' );

is( $stuff->remove_option_at(0), 10, 'removed the correct option' );
lives_ok {
    $stuff->insert_option_at(0, 10);
}
'inserted 10';
is_deeply( $stuff->options, [ 10, 12 ], 'got options' );

is( $stuff->remove_last_option,  12, 'removed the last option' );
is( $stuff->remove_first_option, 10, 'removed the first option' );

is_deeply( $stuff->options, [], 'no options anymore' );

ok( $stuff->has_no_options, 'no options' );
is( $stuff->num_options, 0, 'got no options' );

lives_ok {
    $stuff->add_options;
}
'set the option ok';

lives_ok {
    $stuff->add_options( 1, 2, 3 );
}
'set the option okay';

is_deeply( $stuff->options, [ 1, 2, 3 ], 'got options now' );

ok( !$stuff->has_no_options, 'has options' );
is( $stuff->num_options, 3, 'got 3 options' );

is( $stuff->get_option_at(0), 1, 'get option at index 0' );
is( $stuff->get_option_at(1), 2, 'get option at index 1' );
is( $stuff->get_option_at(2), 3, 'get option at index 2' );

lives_ok {
    $stuff->set_option_at( 1, 100 );
}
'set the option okay';

is( $stuff->get_option_at(1), 100, 'get option at index 1' );

lives_ok {
    $stuff->add_options( 10, 15 );
}
'set the option okay';

is_deeply( $stuff->options, [ 1, 100, 3, 10, 15 ],
    'got more options now' );

is( $stuff->num_options, 5, 'got 5 options' );

is( $stuff->remove_last_option, 15, 'removed the last option' );

is( $stuff->num_options, 4, 'got 4 options' );
is_deeply( $stuff->options, [ 1, 100, 3, 10 ], 'got diff options now' );

lives_ok {
    $stuff->insert_options( 10, 20 );
}
'set the option okay';

lives_ok {
    $stuff->insert_options;
}
'set the option okay';

is( $stuff->num_options, 6, 'got 6 options' );
is_deeply( $stuff->options, [ 10, 20, 1, 100, 3, 10 ],
    'got diff options now' );

is( $stuff->get_option_at(0), 10,  'get option at index 0' );
is( $stuff->get_option_at(1), 20,  'get option at index 1' );
is( $stuff->get_option_at(3), 100, 'get option at index 3' );

is( $stuff->remove_first_option, 10, 'getting the first option' );

is( $stuff->num_options,      5,  'got 5 options' );
is( $stuff->get_option_at(0), 20, 'get option at index 0' );

$stuff->clear_options;
is_deeply( $stuff->options, [], "clear options" );

$stuff->add_options( 5, 1, 2, 3 );
$stuff->sort_options_in_place;
is_deeply( $stuff->options, [ 1, 2, 3, 5 ],
    "sort options in place (default sort order)" );

$stuff->sort_options_in_place( sub { $_[1] <=> $_[0] } );
is_deeply( $stuff->options, [ 5, 3, 2, 1 ],
    "sort options in place (descending order)" );

$stuff->clear_options();
$stuff->add_options( 5, 1, 2, 3 );
lives_ok {
    $stuff->descending_options();
}
'curried sort in place lives ok';

is_deeply( $stuff->options, [ 5, 3, 2, 1 ], "sort currying" );

throws_ok { $stuff->sort_options_in_place('foo') }
qr/Argument must be a code reference/,
    'error when sort_in_place receives a non-coderef argument';

$stuff->clear_options;

lives_ok {
    $stuff->add_options('tree');
}
'set the options okay';

lives_ok {
    $stuff->add_options_with_speed( 'compatible', 'safe' );
}
'add options with speed okay';

is_deeply(
    $stuff->options, [qw/tree funrolls funbuns compatible safe/],
    'check options after add_options_with_speed'
);

lives_ok {
    $stuff->prepend_prerequisites_along_with();
}
'add prerequisite options okay';

$stuff->clear_options;
$stuff->add_options( 1, 2 );

lives_ok {
    $stuff->splice_options( 1, 0, 'foo' );
}
'splice_options works';

is_deeply(
    $stuff->options, [ 1, 'foo', 2 ],
    'splice added expected option'
);

lives_ok {
    $stuff->splice_options( 1, 0 );
}
'splice_options works';

lives_ok {
    $stuff->splice_options;
}
'splice_options works';

is_deeply(
    $stuff->options, [ ],
    'splice worked as expected'
);

is( $stuff->option_accessor( 1 => 'foo++' ), 'foo++' );
is( $stuff->option_accessor(1), 'foo++' );

$stuff->clear_options;
$stuff->add_options( 1 .. 10 );

is_deeply(
    [ $stuff->filter_options( sub { $_ % 2 == 0 } ) ],
    [ 2, 4, 6, 8, 10 ],
    'got the right filtered values'
);

is_deeply(
    [ $stuff->map_options( sub { $_ * 2 } ) ],
    [ 2, 4, 6, 8, 10, 12, 14, 16, 18, 20 ],
    'got the right mapped values'
);

is( $stuff->find_option( sub { $_ % 2 == 0 } ), 2,
    'found the right option' );

is( $stuff->join_options(':'), '1:2:3:4:5:6:7:8:9:10',
    'joined the list of options by :' );

is_deeply(
    [ $stuff->sorted_options ], [ sort ( 1 .. 10 ) ],
    'got sorted options (default sort order)'
);
is_deeply(
    [ $stuff->sorted_options( sub { $_[1] <=> $_[0] } ) ],
    [ sort { $b <=> $a } ( 1 .. 10 ) ],
    'got sorted options (descending sort order)'
);

throws_ok { $stuff->sorted_options('foo') }
qr/Argument must be a code reference/,
    'error when sort receives a non-coderef argument';

is_deeply( [ sort { $a <=> $b } $stuff->randomized_options ], [ 1 .. 10 ], 'got sorted shuffled options' );

my @pairs;
$stuff->pairwise_options(sub { push @pairs, [@_] });
is_deeply( \@pairs, [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7, 8 ], [ 9, 10 ] ], 'did 2 natatime' );

# test the currying
is_deeply( [ $stuff->less_than_five() ], [ 1 .. 4 ], 'got options less than five (grep)' );

is_deeply( [ $stuff->up_by_one() ], [ 2 .. 11 ], 'got incremented options by 1 (map)' );

is( $stuff->dashify, '1-2-3-4-5-6-7-8-9-10', 'got joined options by -' );

is_deeply( [ $stuff->descending ], [ reverse 1 .. 10 ], 'got sorted options descending'  );

is( $stuff->product, 3628800, 'got product of options (reduce)' );

my $other_stuff = Stuff->new( options => [ 1, 1, 2, 3, 5 ] );
is_deeply( [ $other_stuff->unique_options ], [1, 2, 3, 5], 'got unique options' );

## check some errors

dies_ok {
    $stuff->set_option(5, {});
}
'could not add a hash ref where a string is expected';

dies_ok {
    Stuff->new( options => [ undef, 10, undef, 20 ] );
}
'bad constructor params';

dies_ok {
    $stuff->first(undef);
}
'rejects first of an invalid type';

dies_ok {
    $stuff->add_options(undef);
}
'rejects push of an invalid type';

dies_ok {
    $stuff->insert_options(undef);
}
'rejects unshift of an invalid type';

dies_ok {
    $stuff->set_option_at( 0, undef );
}
'rejects set of an invalid type';

dies_ok {
    $stuff->insert_option_at( 0, undef );
}
'rejects insert of an invalid type';

dies_ok {
    $stuff->sort_in_place_options(undef);
}
'sort rejects arg of invalid type';

dies_ok {
    $stuff->option_accessor();
}
'accessor rejects 0 args';

dies_ok {
    $stuff->option_accessor( 1, 2, 3 );
}
'accessor rejects 3 args';

dies_ok {
    $stuff->join;
}
'join rejects invalid separator';

dies_ok {
    $stuff->remove_option_at;
}
'delete rejects invalid index';

dies_ok {
    $stuff->get_option_at;
}
'get rejects invalid index';

dies_ok {
    $stuff->set_option_at;
}
'set rejects invalid index/value';

dies_ok {
    $stuff->insert_option_at;
}
'insert rejects invalid index/value';

## test the meta

my $options = $stuff->meta->get_attribute('options');
does_ok( $options, 'Moose::Meta::Attribute::Native::Trait::Array' );

is_deeply(
    $options->handles,
    {
        'add_options'           => 'push',
        'remove_last_option'    => 'pop',
        'remove_first_option'   => 'shift',
        'remove_option_at'      => 'delete',
        'insert_options'        => 'unshift',
        'insert_option_at'      => 'insert',
        'get_option_at'         => 'get',
        'set_option_at'         => 'set',
        'num_options'           => 'count',
        'has_no_options'        => 'is_empty',
        'clear_options'         => 'clear',
        'splice_options'        => 'splice',
        'sort_options_in_place' => 'sort_in_place',
        'option_accessor'       => 'accessor',
        'add_options_with_speed' =>
            [ 'push' => 'funrolls', 'funbuns' ],
        'prepend_prerequisites_along_with' =>
            [ 'unshift' => 'first', 'second' ],
        'descending_options' =>
            [ 'sort_in_place' => $sort_in_place ],
        'map_options',         => 'map',
        'filter_options'       => 'grep',
        'find_option'          => 'first',
        'join_options'         => 'join',
        'sorted_options'       => 'sort',
        'randomized_options'   => 'shuffle',
        'unique_options'       => 'uniq',
        'less_than_five'       => [ grep => $less ],
        'up_by_one'            => [ map => $up ],
        'pairwise_options'     => [ natatime => 2 ],
        'dashify'    => [ join => '-' ],
        'descending' => [ sort => $sort ],
        'product'    => [ reduce => $prod ],
    },
    'got the right handles mapping'
);

is( $options->type_constraint->type_parameter, 'Str',
    'got the right container type' );
