#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More;
use Test::Exception;

BEGIN {
    eval "use Module::Refresh;";
    plan skip_all => "Module::Refresh is required for this test" if $@;        
    plan no_plan => 1;    
}

use_ok('Bar');

lives_ok {
    Module::Refresh->new->refresh_module('Bar.pm')
} '... successfully refreshed Bar';

