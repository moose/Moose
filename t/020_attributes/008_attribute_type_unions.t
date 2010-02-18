#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;


{
    package Foo;
    use Moose;

    has 'bar' => (is => 'rw', isa => 'ArrayRef | HashRef');
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

lives_ok {
    $foo->bar([])
} '... set bar successfully with an ARRAY ref';

lives_ok {
    $foo->bar({})
} '... set bar successfully with a HASH ref';

dies_ok {
    $foo->bar(100)
} '... couldnt set bar successfully with a number';

dies_ok {
    $foo->bar(sub {})
} '... couldnt set bar successfully with a CODE ref';

# check the constructor

lives_ok {
    Foo->new(bar => [])
} '... created new Foo with bar successfully set with an ARRAY ref';

lives_ok {
    Foo->new(bar => {})
} '... created new Foo with bar successfully set with a HASH ref';

dies_ok {
    Foo->new(bar => 50)
} '... didnt create a new Foo with bar as a number';

dies_ok {
    Foo->new(bar => sub {})
} '... didnt create a new Foo with bar as a CODE ref';

{
    package Bar;
    use Moose;

    has 'baz' => (is => 'rw', isa => 'Str | CodeRef');
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');

lives_ok {
    $bar->baz('a string')
} '... set baz successfully with a string';

lives_ok {
    $bar->baz(sub { 'a sub' })
} '... set baz successfully with a CODE ref';

dies_ok {
    $bar->baz(\(my $var1))
} '... couldnt set baz successfully with a SCALAR ref';

dies_ok {
    $bar->baz({})
} '... couldnt set bar successfully with a HASH ref';

# check the constructor

lives_ok {
    Bar->new(baz => 'a string')
} '... created new Bar with baz successfully set with a string';

lives_ok {
    Bar->new(baz => sub { 'a sub' })
} '... created new Bar with baz successfully set with a CODE ref';

dies_ok {
    Bar->new(baz => \(my $var2))
} '... didnt create a new Bar with baz as a number';

dies_ok {
    Bar->new(baz => {})
} '... didnt create a new Bar with baz as a HASH ref';

done_testing;
