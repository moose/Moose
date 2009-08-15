#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

{
    package Foo;

    use Moose;

    use overload '""' => sub {''};

    sub bug { 'plenty' }

    __PACKAGE__->meta->make_immutable;
}

ok(Foo->new()->bug(), 'call constructor on object reference with overloading');

