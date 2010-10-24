#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    has 'bar' => (is => 'rw', isa => 'ArrayRef | HashRef');
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

ok ! exception {
    $foo->bar([])
}, '... set bar successfully with an ARRAY ref';

ok ! exception {
    $foo->bar({})
}, '... set bar successfully with a HASH ref';

ok exception {
    $foo->bar(100)
}, '... couldnt set bar successfully with a number';

ok exception {
    $foo->bar(sub {})
}, '... couldnt set bar successfully with a CODE ref';

# check the constructor

ok ! exception {
    Foo->new(bar => [])
}, '... created new Foo with bar successfully set with an ARRAY ref';

ok ! exception {
    Foo->new(bar => {})
}, '... created new Foo with bar successfully set with a HASH ref';

ok exception {
    Foo->new(bar => 50)
}, '... didnt create a new Foo with bar as a number';

ok exception {
    Foo->new(bar => sub {})
}, '... didnt create a new Foo with bar as a CODE ref';

{
    package Bar;
    use Moose;

    has 'baz' => (is => 'rw', isa => 'Str | CodeRef');
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');

ok ! exception {
    $bar->baz('a string')
}, '... set baz successfully with a string';

ok ! exception {
    $bar->baz(sub { 'a sub' })
}, '... set baz successfully with a CODE ref';

ok exception {
    $bar->baz(\(my $var1))
}, '... couldnt set baz successfully with a SCALAR ref';

ok exception {
    $bar->baz({})
}, '... couldnt set bar successfully with a HASH ref';

# check the constructor

ok ! exception {
    Bar->new(baz => 'a string')
}, '... created new Bar with baz successfully set with a string';

ok ! exception {
    Bar->new(baz => sub { 'a sub' })
}, '... created new Bar with baz successfully set with a CODE ref';

ok exception {
    Bar->new(baz => \(my $var2))
}, '... didnt create a new Bar with baz as a number';

ok exception {
    Bar->new(baz => {})
}, '... didnt create a new Bar with baz as a HASH ref';

done_testing;
