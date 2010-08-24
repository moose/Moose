#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::NoTabs' => '0.8', # skip all if not installed
};

# Module::Install has tabs, so we can't check 'inc' or ideally '.'
all_perl_files_ok('lib', 't', 'xt');

