#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose;

    has foo => (
        is      => 'ro',
        default => 'FOO',
    );
}

{
    package Foo::Sub;
    use Moose;

    extends 'Foo';
}

{
    my $foo_sub = Foo::Sub->new;
    isa_ok($foo_sub, 'Foo');
    is($foo_sub->foo, 'FOO', 'inheritance works');
    ok(!Foo::Sub->meta->has_method('new'),
       'Foo::Sub doesn\'t have its own new method');
}

$_->meta->make_immutable for qw(Foo Foo::Sub);

{
    my $foo_sub = Foo::Sub->new;
    isa_ok($foo_sub, 'Foo');
    is($foo_sub->foo, 'FOO', 'inheritance works (immutable)');
    ok(Foo::Sub->meta->has_method('new'),
       'Foo::Sub has its own new method (immutable)');
}

{
    package Foo::OtherSub;
    use Moose;

    extends 'Foo';
}

{
    my $foo_othersub = Foo::OtherSub->new;
    isa_ok($foo_othersub, 'Foo');
    is($foo_othersub->foo, 'FOO',
       'inheritance works (immutable when extending)');
    ok(!Foo::OtherSub->meta->has_method('new'),
       'Foo::OtherSub doesn\'t have its own new method (immutable when extending)');
}

Foo::OtherSub->meta->make_immutable;

{
    my $foo_othersub = Foo::OtherSub->new;
    isa_ok($foo_othersub, 'Foo');
    is($foo_othersub->foo, 'FOO', 'inheritance works (all immutable)');
    ok(Foo::OtherSub->meta->has_method('new'),
       'Foo::OtherSub has its own new method (all immutable)');
}

done_testing;
