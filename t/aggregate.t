#!/usr/bin/perl
use strict;
use warnings;
use Test::Aggregate;
my $tests = Test::Aggregate->new({
    dirs => 'tests',
});
$tests->run;

