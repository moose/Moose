#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;



{
    package Foo;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Int');

    sub DEMOLISH { }
}

{
    package Bar;
    use Moose;

    extends qw(Foo);
    has 'bar' => (is => 'rw', isa => 'Int');

    sub DEMOLISH { }
}

lives_ok {
    Bar->new();
} 'Bar->new()';

lives_ok {
    my $bar = Bar->new();
    $bar->meta->make_immutable;
} 'Bar->meta->make_immutable';