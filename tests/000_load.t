#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

package Foo;

# Moose will issue a warning if we try to load it from the main
# package.
::use_ok('Moose');


