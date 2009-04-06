#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
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
    Bar->meta->make_immutable;
} 'Bar->meta->make_immutable';

is( Bar->meta->get_method('DESTROY')->package_name, 'Bar',
    'Bar has a DESTROY method in the Bar class (not inherited)' );
