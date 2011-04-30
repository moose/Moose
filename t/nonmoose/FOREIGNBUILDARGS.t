#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Foo;

    sub new {
        my $class = shift;
        bless { foo_base => $_[0] }, $class;
    }

    sub foo_base { shift->{foo_base} }
}

{
    package Foo::Moose;
    use Moose;

    extends 'Foo';

    has foo => (
        is => 'rw',
    );

    sub FOREIGNBUILDARGS {
        my $class = shift;
        my %args = @_;
        return "$args{foo}_base";
    }
}

{
    package Bar::Moose;
    use Moose;

    extends 'Foo';

    has bar => (
        is => 'rw',
    );

    sub FOREIGNBUILDARGS {
        my $class = shift;
        return "$_[0]_base";
    }

    sub BUILDARGS {
        my $class = shift;
        return { bar => shift };
    }
}

{
    package Baz::Moose;
    use Moose;
    extends 'Bar::Moose';

    has baz => (
        is => 'rw',
    );
}

with_immutable {
    my $foo = Foo::Moose->new(foo => 'bar');
    is($foo->foo,  'bar', 'subclass constructor gets the right args');
    is($foo->foo_base,  'bar_base', 'subclass constructor gets the right args');
    my $bar = Bar::Moose->new('baz');
    is($bar->bar, 'baz', 'subclass constructor gets the right args');
    is($bar->foo_base, 'baz_base', 'subclass constructor gets the right args');
    my $baz = Baz::Moose->new('bazbaz');
    is($baz->bar, 'bazbaz', 'extensions of extensions of the nonmoose class respect BUILDARGS');
    is($baz->foo_base, 'bazbaz_base', 'extensions of extensions of the nonmoose class respect FOREIGNBUILDARGS');
} qw(Foo::Moose Bar::Moose Baz::Moose);

done_testing;
