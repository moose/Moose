#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Moose;

{
    package Foo;

    sub create {
        my $class = shift;
        my %params = @_;
        bless { foo => ($params{foo} || 'FOO') }, $class;
    }

    sub foo { shift->{foo} }
}

{
    package Foo::Sub;
    use Moose;

    extends 'Foo' => { -constructor_name => 'create' };

    has bar => (
        is      => 'ro',
        isa     => 'Str',
        default => 'BAR',
    );
}

with_immutable {
    my $foo = Foo::Sub->create;
    is($foo->foo, 'FOO', "nonmoose constructor called");
    is($foo->bar, 'BAR', "moose constructor called");
} 'Foo::Sub';

{
    package Foo::BadSub;
    use Moose;

    ::like(
        ::exception {
            extends 'Foo' => { -constructor_name => 'something_else' };
        },
        qr/You specified 'something_else' as the constructor for Foo, but Foo has no method by that name/,
        "specifying an incorrect constructor name dies"
    );
}

{
    package Foo::Mixin;

    sub thing {
        return shift->foo . 'BAZ';
    }
}

{
    package Foo::Sub2;
    use Moose;

    extends 'Foo::Mixin', 'Foo' => { -constructor_name => 'create' };

    has bar => (
        is      => 'ro',
        isa     => 'Str',
        default => 'BAR',
    );
}

with_immutable {
    my $foo = Foo::Sub2->create;
    is($foo->foo, 'FOO', "nonmoose constructor called");
    is($foo->bar, 'BAR', "moose constructor called");
    is($foo->thing, 'FOOBAZ', "mixin still works");
} 'Foo::Sub2';

{
    package Bar;

    sub make {
        my $class = shift;
        my %params = @_;
        bless { baz => ($params{baz} || 'BAZ') }, $class;
    }
}

{
    package Foo::Bar::Sub;
    use Moose;

    ::like(
        ::exception {
            extends 'Bar' => { -constructor_name => 'make' },
                    'Foo' => { -constructor_name => 'create' };
        },
        qr/You have already specified Bar::make as the parent constructor; Foo::create cannot also be the constructor/,
        "can't specify two parent constructors"
    );
}

done_testing;
