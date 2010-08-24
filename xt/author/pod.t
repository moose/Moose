#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Pod' => '1.14', # skip all if not installed
};

all_pod_files_ok();
