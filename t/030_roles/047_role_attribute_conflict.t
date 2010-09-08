use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package My::Role1;
    use Moose::Role;

    has foo => (
        is => 'ro',
    );

}

{
    package My::Role2;
    use Moose::Role;

    has foo => (
        is => 'ro',
    );

    ::throws_ok { with 'My::Role1' } qr/attribute conflict.+My::Role2.+foo/,
        'attribute conflict when composing one role into another';
}

done_testing;
