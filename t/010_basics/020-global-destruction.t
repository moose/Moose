#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

our $expected_igd = 0;
package Foo;
use Moose;

sub DEMOLISH {
    my $self = shift;
    my ($igd) = @_;
    ::is($igd, $::expected_igd,
         "in_global_destruction state is passed to DEMOLISH properly");
}

package main;
{
    my $foo = Foo->new;
}
$expected_igd = 1;
# Test::Builder checks for a valid plan at END time, which is before global
# destruction, so need to test that in a subprocess
unless (fork) {
    our $foo = Foo->new;
    exit;
}
wait;
# but stuff that happens in a subprocess doesn't update Test::Builder's state
# in this process, so do that manually here
my $builder = Test::More->builder;
$builder->current_test($builder->current_test + 1);
