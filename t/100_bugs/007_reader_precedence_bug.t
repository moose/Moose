#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;

use MetaTest;

{
    package Foo;
    use Moose;
    has 'foo' => ( is => 'ro', reader => 'get_foo' );
}

{
    my $foo = Foo->new(foo => 10);
    skip_meta {
       my $reader = $foo->meta->get_attribute('foo')->reader;
       is($reader, 'get_foo',
          'reader => "get_foo" has correct presedence');
       is($foo->$reader, 10, "Reader works as expected");
    } 2;
    can_ok($foo, 'get_foo');
}

done_testing;
