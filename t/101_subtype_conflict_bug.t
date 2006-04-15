#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More tests => 3;

BEGIN {
    use_ok('Moose');           
}

use_ok('MyMooseA');
use_ok('MyMooseB');