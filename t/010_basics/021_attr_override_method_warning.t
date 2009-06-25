#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings,@_ };
    eval <<EOP;
package MyThingy;
use Moose;

has foo => ( is => 'rw' );
sub foo { 'omglolbbq' }

package main;
EOP

is( scalar(@warnings), 1, 'got 1 warning' );
like( $warnings[0], qr/\bfoo\b.+redefine/, 'got a redefinition warning that mentions redefining or overriding or something');

