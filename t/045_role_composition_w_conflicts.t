#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN {  
    use_ok('Moose');
    use_ok('Moose::Role');
}