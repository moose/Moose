use strict;
use warnings;

use Test::Needs { 'Types::Standard' => 0.021_03 };
use Test::More;
use Test::Fatal;

my @array_delegations = qw(
    accessor
    clear
    count
    delete
    elements
    first_index
    first
    get
    grep
    insert
    is_empty
    join
    map
    natatime
    pop
    push
    reduce
    set
    shallow_clone
    shift
    shuffle
    sort_in_place
    sort
    splice
    uniq
    unshift
);

my @hash_delegations = qw(
    accessor
    clear
    count
    defined
    delete
    elements
    exists
    get
    is_empty
    keys
    kv
    set
    shallow_clone
    values
);

is(
    exception {
        package MyClass;

        use Moose;
        use Types::Standard qw/ ArrayRef HashRef Str /;

        has plain_array => (
            is      => 'ro',
            isa     => ArrayRef,
            traits  => ['Array'],
            handles => {
                map { $_ . '_plain_array' => $_ } @array_delegations
            }
        );

        has array_of_str => (
            is      => 'ro',
            isa     => ArrayRef[Str],
            traits  => [ 'Array' ],
            handles => {
                map { $_ . '_array_of_str' => $_ } @array_delegations
            }
        );

        has plain_hash => (
            is      => 'ro',
            isa     => HashRef,
            traits  => ['Hash'],
            handles => {
                map { $_ . '_plain_hash' => $_ } @hash_delegations
            }
        );

        has hash_of_str => (
            is      => 'ro',
            isa     => HashRef[Str],
            traits  => [ 'Hash' ],
            handles => {
                map { $_ . '_hash_of_str' => $_ } @hash_delegations
            }
        );
    },
    undef,
    'Type::Tiny is usable with native traits',
);

done_testing;
