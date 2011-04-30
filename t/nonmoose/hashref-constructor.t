#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;

    sub new {
        my $class = shift;
        bless { ref($_[0]) ? %{$_[0]} : @_ }, $class;
    }

    sub foo {
        my $self = shift;
        $self->{foo};
    }
}

{
    package Bar;
    use Moose;

    extends 'Foo';

    has _bar => (
        init_arg => 'bar',
        reader   => 'bar',
    );

    __PACKAGE__->meta->make_immutable;
}

{
    package Baz;
    use Moose;

    extends 'Bar';

    has _baz => (
        init_arg => 'baz',
        reader   => 'baz',
    );
}

{
    my $baz;
    is(exception { $baz = Baz->new( foo => 1, bar => 2, baz => 3 ) }, undef,
       "constructor lives");
    is($baz->foo, 1, "foo set");
    is($baz->bar, 2, "bar set");
    is($baz->baz, 3, "baz set");

}

{
    my $baz;
    is(exception { $baz = Baz->new({foo => 1, bar => 2, baz => 3}) }, undef,
       "constructor lives (hashref)");
    is($baz->foo, 1, "foo set (hashref)");
    is($baz->bar, 2, "bar set (hashref)");
    is($baz->baz, 3, "baz set (hashref)");
}

done_testing;
