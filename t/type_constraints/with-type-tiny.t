use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Test::Requires { 'Types::Standard' => 0.021_03 };

is(
    exception {
        package MyClass;

        use Moose;
        use Types::Standard qw/ HashRef Str /;
        has foo => (
            is      => 'ro',
            isa     => HashRef[Str],
            traits  => [ 'Hash' ],
            handles => { clear_foo => 'clear' },
        );
    },
    undef,
    'Type::Tiny is usable with native traits',
);

done_testing;
