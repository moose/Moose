#!/usr/bin/perl

use strict;
use warnings;


{
    package Foo;
    use Moose;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;

        print $igd;
    }
}

our $foo = Foo->new;
