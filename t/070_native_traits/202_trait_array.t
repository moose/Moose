#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Moose 'does_ok';

my $sort;

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
            'insert_options'        => 'unshift',
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
                [ 'sort_in_place' => ($sort = sub { $_[1] <=> $_[0] }) ],
        }
    );
}

my $stuff = Stuff->new( options => [ 10, 12 ] );
isa_ok( $stuff, 'Stuff' );

can_ok( $stuff, $_ ) for qw[
    add_options
    remove_last_option
    remove_first_option
    insert_options
    get_option_at
    set_option_at
    num_options
    clear_options
    has_no_options
    sort_options_in_place
    option_accessor
];

is_deeply( $stuff->options, [ 10, 12 ], '... got options' );

ok( !$stuff->has_no_options, '... we have options' );
is( $stuff->num_options, 2, '... got 2 options' );

is( $stuff->remove_last_option,  12, '... removed the last option' );
is( $stuff->remove_first_option, 10, '... removed the last option' );

is_deeply( $stuff->options, [], '... no options anymore' );

ok( $stuff->has_no_options, '... no options' );
is( $stuff->num_options, 0, '... got no options' );

lives_ok {
    $stuff->add_options( 1, 2, 3 );
}
'... set the option okay';

is_deeply( $stuff->options, [ 1, 2, 3 ], '... got options now' );

ok( !$stuff->has_no_options, '... has options' );
is( $stuff->num_options, 3, '... got 3 options' );

is( $stuff->get_option_at(0), 1, '... get option at index 0' );
is( $stuff->get_option_at(1), 2, '... get option at index 1' );
is( $stuff->get_option_at(2), 3, '... get option at index 2' );

lives_ok {
    $stuff->set_option_at( 1, 100 );
}
'... set the option okay';

is( $stuff->get_option_at(1), 100, '... get option at index 1' );

lives_ok {
    $stuff->add_options( 10, 15 );
}
'... set the option okay';

is_deeply( $stuff->options, [ 1, 100, 3, 10, 15 ],
    '... got more options now' );

is( $stuff->num_options, 5, '... got 5 options' );

is( $stuff->remove_last_option, 15, '... removed the last option' );

is( $stuff->num_options, 4, '... got 4 options' );
is_deeply( $stuff->options, [ 1, 100, 3, 10 ], '... got diff options now' );

lives_ok {
    $stuff->insert_options( 10, 20 );
}
'... set the option okay';

is( $stuff->num_options, 6, '... got 6 options' );
is_deeply( $stuff->options, [ 10, 20, 1, 100, 3, 10 ],
    '... got diff options now' );

is( $stuff->get_option_at(0), 10,  '... get option at index 0' );
is( $stuff->get_option_at(1), 20,  '... get option at index 1' );
is( $stuff->get_option_at(3), 100, '... get option at index 3' );

is( $stuff->remove_first_option, 10, '... getting the first option' );

is( $stuff->num_options,      5,  '... got 5 options' );
is( $stuff->get_option_at(0), 20, '... get option at index 0' );

$stuff->clear_options;
is_deeply( $stuff->options, [], "... clear options" );

$stuff->add_options( 5, 1, 2, 3 );
$stuff->sort_options_in_place;
is_deeply( $stuff->options, [ 1, 2, 3, 5 ],
    "... sort options in place (default sort order)" );

$stuff->sort_options_in_place( sub { $_[1] <=> $_[0] } );
is_deeply( $stuff->options, [ 5, 3, 2, 1 ],
    "... sort options in place (descending order)" );

$stuff->clear_options();
$stuff->add_options( 5, 1, 2, 3 );
lives_ok {
    $stuff->descending_options();
}
'... curried sort in place lives ok';

is_deeply( $stuff->options, [ 5, 3, 2, 1 ], "... sort currying" );

throws_ok { $stuff->sort_options_in_place('foo') }
qr/Argument must be a code reference/,
    'error when sort_in_place receives a non-coderef argument';

$stuff->clear_options;

lives_ok {
    $stuff->add_options('tree');
}
'... set the options okay';

lives_ok {
    $stuff->add_options_with_speed( 'compatible', 'safe' );
}
'... add options with speed okay';

is_deeply(
    $stuff->options, [qw/tree funrolls funbuns compatible safe/],
    'check options after add_options_with_speed'
);

lives_ok {
    $stuff->prepend_prerequisites_along_with();
}
'... add prerequisite options okay';

$stuff->clear_options;
$stuff->add_options( 1, 2 );

lives_ok {
    $stuff->splice_options( 1, 0, 'foo' );
}
'... splice_options works';

is_deeply(
    $stuff->options, [ 1, 'foo', 2 ],
    'splice added expected option'
);

is( $stuff->option_accessor( 1 => 'foo++' ), 'foo++' );
is( $stuff->option_accessor(1), 'foo++' );

## check some errors

#dies_ok {
#    $stuff->insert_options(undef);
#} '... could not add an undef where a string is expected';
#
#dies_ok {
#    $stuff->set_option(5, {});
#} '... could not add a hash ref where a string is expected';

dies_ok {
    Stuff->new( options => [ undef, 10, undef, 20 ] );
}
'... bad constructor params';

dies_ok {
    my $stuff = Stuff->new();
    $stuff->add_options(undef);
}
'... rejects push of an invalid type';

dies_ok {
    my $stuff = Stuff->new();
    $stuff->insert_options(undef);
}
'... rejects unshift of an invalid type';

dies_ok {
    my $stuff = Stuff->new();
    $stuff->set_option_at( 0, undef );
}
'... rejects set of an invalid type';

dies_ok {
    my $stuff = Stuff->new();
    $stuff->sort_in_place_options(undef);
}
'... sort rejects arg of invalid type';

dies_ok {
    my $stuff = Stuff->new();
    $stuff->option_accessor();
}
'... accessor rejects 0 args';

dies_ok {
    my $stuff = Stuff->new();
    $stuff->option_accessor( 1, 2, 3 );
}
'... accessor rejects 3 args';

## test the meta

my $options = $stuff->meta->get_attribute('options');
does_ok( $options, 'Moose::Meta::Attribute::Native::Trait::Array' );

is_deeply(
    $options->handles,
    {
        'add_options'           => 'push',
        'remove_last_option'    => 'pop',
        'remove_first_option'   => 'shift',
        'insert_options'        => 'unshift',
        'get_option_at'         => 'get',
        'set_option_at'         => 'set',
        'num_options'           => 'count',
        'has_no_options'        => 'is_empty',
        'clear_options'         => 'clear',
        'splice_options'        => 'splice',
        'sort_options_in_place' => 'sort_in_place',
        'option_accessor'       => 'accessor',
        'add_options_with_speed' => [ 'push' => 'funrolls', 'funbuns' ],
        'prepend_prerequisites_along_with' =>
            [ 'unshift' => 'first', 'second' ],
        'descending_options' => [ 'sort_in_place' => $sort ],
    },
    '... got the right handles mapping'
);

is( $options->type_constraint->type_parameter, 'Str',
    '... got the right container type' );

done_testing;
