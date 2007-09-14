#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

{
    package Foo;

    sub new { 
        bless({}, 'Foo') 
    }
    
    sub a { 'Foo::a' }
}

{
    package Bar;
    use Moose;

    ::lives_ok {
        has 'baz' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => qr/^a$/,
        );
    } '... can create the attribute with delegations';
    
}

my $bar;
lives_ok {
    $bar = Bar->new;
} '... created the object ok';
isa_ok($bar, 'Bar');

is($bar->a, 'Foo::a', '... got the right delgated value');

{
    package Baz;
    use Moose;

    ::lives_ok {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => qr/.*/,
        );
    } '... can create the attribute with delegations';
    
}

my $baz;
lives_ok {
    $baz = Baz->new;
} '... created the object ok';
isa_ok($baz, 'Baz');

is($baz->a, 'Foo::a', '... got the right delgated value');








