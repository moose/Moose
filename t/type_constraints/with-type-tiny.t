use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Test::Requires 'Types::Standard';

is exception {
    package MyClass;

    use Moose;
    use Types::Standard qw/ HashRef Str /;
    has foo => (
        is      => 'ro',
        isa     => HashRef[Str],
        traits  => [ 'Hash' ],
        handles => { clear_foo => 'clear' },
    );
}, undef,
    'Type::Tiny usable with native traits';

done_testing;
