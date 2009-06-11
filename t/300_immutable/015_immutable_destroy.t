#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    package FooBar;
    use Moose;

    has 'name' => (is => 'ro');

    sub DESTROY { shift->name }

    __PACKAGE__->meta->make_immutable;
}

my $f = FooBar->new(name => "SUSAN");

is($f->DESTROY, "SUSAN", "Did moose overload DESTROY?");
