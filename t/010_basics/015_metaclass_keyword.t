#!/usr/bin/perl

{

    package Foo;
    use Test::More tests => 1;
    use Moose;

    is( metaclass(), __PACKAGE__->meta,
        'metaclass and __PACKAGE__->meta are the same' );
}

