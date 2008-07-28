#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

{
    package My::SimpleTrait;

    use Moose::Role;

    sub simple { return 5 }
}

{
    package Foo;

    use Moose -traits => [ 'My::SimpleTrait' ];
}

can_ok( Foo->meta(), 'simple' );
is( Foo->meta()->simple(), 5,
    'Foo->meta()->simple() returns expected value' );

{
    package My::SimpleTrait2;

    use Moose::Role;

    # This needs to happen at begin time so it happens before we apply
    # traits to Bar
    BEGIN {
        has 'attr' =>
            ( is      => 'ro',
              default => 'something',
            );
    }

    sub simple { return 5 }
}

{
    package Bar;

    use Moose -traits => [ 'My::SimpleTrait2' ];
}

can_ok( Bar->meta(), 'simple' );
is( Bar->meta()->simple(), 5,
    'Bar->meta()->simple() returns expected value' );
can_ok( Bar->meta(), 'attr' );
is( Bar->meta()->attr(), 'something',
    'Bar->meta()->attr() returns expected value' );
