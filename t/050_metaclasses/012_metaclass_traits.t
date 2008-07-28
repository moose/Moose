#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

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

{
    package My::SimpleTrait3;

    use Moose::Role;

    # This needs to happen at begin time so it happens before we apply
    # traits to Bar
    BEGIN {
        has 'attr2' =>
            ( is      => 'ro',
              default => 'something',
            );
    }

    sub simple2 { return 55 }
}


{
    package Baz;

    use Moose -traits => [ 'My::SimpleTrait2', 'My::SimpleTrait3' ];
}

can_ok( Baz->meta(), 'simple' );
is( Baz->meta()->simple(), 5,
    'Baz->meta()->simple() returns expected value' );
can_ok( Baz->meta(), 'attr' );
is( Baz->meta()->attr(), 'something',
    'Baz->meta()->attr() returns expected value' );
can_ok( Baz->meta(), 'simple2' );
is( Baz->meta()->simple2(), 55,
    'Baz->meta()->simple2() returns expected value' );
can_ok( Baz->meta(), 'attr2' );
is( Baz->meta()->attr2(), 'something',
    'Baz->meta()->attr2() returns expected value' );
