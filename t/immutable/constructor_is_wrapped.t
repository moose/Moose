use strict;
use warnings;

use Test::Needs 'Test::Output';  # skip all if not installed
use Test::More;

use Test::Output;

{
    package ModdedNew;
    use Moose;

    before 'new' => sub { };
}

{
    package Foo;
    use Moose;

    extends 'ModdedNew';

    ::stderr_like(
        sub { Foo->meta->make_immutable },
        qr/\QNot inlining 'new' for Foo since it has method modifiers which would be lost if it were inlined/,
        'got a warning that Foo may not have an inlined constructor'
    );
}

done_testing;
