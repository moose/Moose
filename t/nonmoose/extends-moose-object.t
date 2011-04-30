#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;

    sub new { bless {}, shift }
}

{
    package Foo::Sub;
    use Moose;

    extends 'Foo';
}

{
    package Bar;
    use Moose;
}

{
    package Bar::Sub;
    use Moose;

    extends 'Bar';
}

is_deeply(\@Foo::Sub::ISA, ['Foo', 'Moose::Object'], "Moose::Object was added");
is_deeply(\@Bar::Sub::ISA, ['Bar'], "Moose::Object wasn't added");

done_testing;
