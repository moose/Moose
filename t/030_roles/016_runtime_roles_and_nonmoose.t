#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Scalar::Util 'blessed';

BEGIN {
    use_ok('Moose');
}


{
    package Dog;
    use Moose::Role;

    sub talk { 'woof' }

    package Foo;
    use Moose;

    has 'dog' => (
        is   => 'rw',
        does => 'Dog',
    );

    no Moose;

    package Bar;

    sub new {
      return bless {}, shift;
    }
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');    

my $foo = Foo->new;
isa_ok($foo, 'Foo');  

ok(!$bar->can( 'talk' ), "... the role is not composed yet");

dies_ok {
    $foo->dog($bar)
} '... and setting the accessor fails (not a Dog yet)';

Dog->meta->apply($bar);

ok($bar->can('talk'), "... the role is now composed at the object level");

is($bar->talk, 'woof', '... got the right return value for the newly composed method');

lives_ok {
    $foo->dog($bar)
} '... and setting the accessor is okay';

