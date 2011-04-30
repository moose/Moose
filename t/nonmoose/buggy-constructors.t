#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Moose;

{
    package Foo;

    sub new { bless {}, shift }
}

{
    package Foo::Sub;
    use Moose;

    extends 'Foo';
}

with_immutable {
    my $foo;
    is(exception { $foo = Foo::Sub->new }, undef,
       "subclassing nonmoose classes with correct constructors works");
    isa_ok($foo, 'Foo');
    isa_ok($foo, 'Foo::Sub');
} 'Foo::Sub';

{
    package BadFoo;

    sub new { bless {} }
}

{
    package BadFoo::Sub;
    use Moose;

    extends 'BadFoo';
}

with_immutable {
    my $foo;
    is(exception { $foo = BadFoo::Sub->new }, undef,
       "subclassing nonmoose classes with incorrect constructors works");
    isa_ok($foo, 'BadFoo');
    isa_ok($foo, 'BadFoo::Sub');
} 'BadFoo::Sub';

{
    package BadFoo2;

    sub new { {} }
}

{
    package BadFoo2::Sub;
    use Moose;

    extends 'BadFoo2';
}

with_immutable {
    my $foo;
    like(exception { $foo = BadFoo2::Sub->new; },
         qr/\QThe constructor for BadFoo2 did not return a blessed instance/,
         "subclassing nonmoose classes with incorrect constructors dies properly");
} 'BadFoo2::Sub';

{
    package BadFoo3;

    sub new { bless {}, 'Something::Else::Entirely' }
}

{
    package BadFoo3::Sub;
    use Moose;

    extends 'BadFoo3';
}

with_immutable {
    my $foo;
    like(exception { $foo = BadFoo3::Sub->new },
         qr/\QThe constructor for BadFoo3 returned an object whose class is not a parent of BadFoo3::Sub/,
         "subclassing nonmoose classes with incorrect constructors dies properly");
} 'BadFoo3::Sub';

done_testing;
