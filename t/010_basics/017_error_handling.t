#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

# This tests the error handling in Moose::Object only

{
    package Foo;
    use Moose;
}

throws_ok { Foo->new('bad') } qr/^\QSingle parameters to new() must be a HASH ref/,
          'A single non-hashref arg to a constructor throws an error';

throws_ok { Foo->does() } qr/^\QYou much supply a role name to does()/,
          'Cannot call does() without a role name';
