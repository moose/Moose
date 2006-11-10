#!/usr/bin/perl

use strict;
use warnings;

use lib '/Users/stevan/Projects/Moose/Moose/Class-MOP/branches/Class-MOP-tranformations/lib';

use lib 't/lib', 'lib';

use Test::More tests => 1;

use_ok('MyMooseObject');