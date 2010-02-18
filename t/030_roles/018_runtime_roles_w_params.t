#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use MetaTest;

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

    skip_meta {
       lives_ok {
           Bar->meta->apply($foo)
       } '... this works';

       is($foo->bar, 'BAR', '... got the expect value');
       ok($foo->can('baz'), '... we have baz method now');
       is($foo->baz, 'BAZ', '... got the expect value');
    } 4;
}

# with extra params ...
{
    my $foo = Foo->new(bar => 'BAR');
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');

    skip_meta {
       lives_ok {
           Bar->meta->apply($foo, (rebless_params => { baz => 'FOO-BAZ' }))
       } '... this works';

       is($foo->bar, 'BAR', '... got the expect value');
       ok($foo->can('baz'), '... we have baz method now');
       is($foo->baz, 'FOO-BAZ', '... got the expect value');
    } 4;
}

# with extra params ...
{
    my $foo = Foo->new(bar => 'BAR');
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');

    skip_meta {
       lives_ok {
           Bar->meta->apply($foo, (rebless_params => { bar => 'FOO-BAR', baz => 'FOO-BAZ' }))
       } '... this works';

       is($foo->bar, 'FOO-BAR', '... got the expect value');
       ok($foo->can('baz'), '... we have baz method now');
       is($foo->baz, 'FOO-BAZ', '... got the expect value');
    } 4;
}

done_testing;
