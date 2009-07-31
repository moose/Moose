#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

{
    package Foo;
    use Moose;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;
        ::ok(
            !$igd,
            'in_global_destruction state is passed to DEMOLISH properly (false)'
        );
    }
}

{
    my $foo = Foo->new;
}

my $igd = `$^X t/010_basics/020-global-destruction-helper.pl`;
ok( $igd,
    'in_global_destruction state is passed to DEMOLISH properly (true)' );
