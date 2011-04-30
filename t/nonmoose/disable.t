#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;

    sub new {
        my $class = shift;
        bless {}, $class;
    }
}

{
    package Foo::Moose;
    use Moose;

    extends 'Foo';
}

{
    package Foo::Moose2;
    use Moose;

    extends 'Foo';
}

ok(Foo::Moose->meta->has_method('new'), 'Foo::Moose has a constructor');

{
    my $method = Foo::Moose->meta->get_method('new');
    Foo::Moose->meta->make_immutable;
    isnt($method, Foo::Moose->meta->get_method('new'),
         'make_immutable replaced the constructor with an inlined version');
}

{
    my $method2 = Foo::Moose2->meta->get_method('new');
    Foo::Moose2->meta->make_immutable(inline_constructor => 0);
    is($method2, Foo::Moose2->meta->get_method('new'),
       'make_immutable doesn\'t replace the constructor if we ask it not to');
}

done_testing;
