#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

{
    package Foo;
    use Moose;
    has 'bar' => (is => 'ro');
    
    package Bar;
    use Moose::Role;
    
    has 'baz' => (is => 'ro', default => 'BAZ');    
}

# normal ...
{
    my $foo = Foo->new(bar => 'BAR');
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');

    lives_ok {
        Bar->meta->apply($foo)
    } '... this works';

    is($foo->bar, 'BAR', '... got the expect value');
    ok($foo->can('baz'), '... we have baz method now');
    is($foo->baz, 'BAZ', '... got the expect value');
}

# with extra params ...
{
    my $foo = Foo->new(bar => 'BAR');
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');

    lives_ok {
        Bar->meta->apply($foo, (rebless_params => { baz => 'FOO-BAZ' }))
    } '... this works';

    is($foo->bar, 'BAR', '... got the expect value');
    ok($foo->can('baz'), '... we have baz method now');
    is($foo->baz, 'FOO-BAZ', '... got the expect value');
}

# with extra params ...
{
    my $foo = Foo->new(bar => 'BAR');
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');

    lives_ok {
        Bar->meta->apply($foo, (rebless_params => { bar => 'FOO-BAR', baz => 'FOO-BAZ' }))
    } '... this works';

    is($foo->bar, 'FOO-BAR', '... got the expect value');
    ok($foo->can('baz'), '... we have baz method now');
    is($foo->baz, 'FOO-BAZ', '... got the expect value');
}


