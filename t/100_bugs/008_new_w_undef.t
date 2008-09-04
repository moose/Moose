#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

{
    package Foo;
    use Moose;    
    has 'foo' => ( is => 'ro' );
}

lives_ok {
    Foo->new(undef);
} '... passing in undef just gets ignored';




