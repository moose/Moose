#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $foo_constructed;

{
    package Foo;

    sub new {
        my $class = shift;
        bless {}, $class;
    }
}

{
    package Foo::Moose;
    use Moose;

    extends 'Foo';

    after new => sub {
        $foo_constructed = 1;
    };
}

{
    package Foo::Moose2;
    use Moose;

    extends 'Foo';

    sub new {
        my $class = shift;
        $foo_constructed = 1;
        return $class->meta->new_object(@_);
    }
}

{
    my $method = Foo::Moose->meta->get_method('new');
    isa_ok($method, 'Class::MOP::Method::Wrapped');

    {
        undef $foo_constructed;
        Foo::Moose->new;
        ok($foo_constructed, 'method modifier called for the constructor');
    }

    {
        # we don't care about the warning that moose isn't going to inline our
        # constructor - this is the behavior we're testing
        local $SIG{__WARN__} = sub {};
        Foo::Moose->meta->make_immutable;
    }

    is($method, Foo::Moose->meta->get_method('new'),
       'make_immutable doesn\'t overwrite constructor with method modifiers');

    {
        undef $foo_constructed;
        Foo::Moose->new;
        ok($foo_constructed,
           'method modifier called for the constructor (immutable)');
    }
}

{
    my $method = Foo::Moose2->meta->get_method('new');

    {
        undef $foo_constructed;
        Foo::Moose2->new;
        ok($foo_constructed, 'custom constructor called');
    }

    # still need to specify inline_constructor => 0 when overriding new
    # manually
    Foo::Moose2->meta->make_immutable(inline_constructor => 0);
    is($method, Foo::Moose2->meta->get_method('new'),
       'make_immutable doesn\'t overwrite custom constructor');

    {
        undef $foo_constructed;
        Foo::Moose2->new;
        ok($foo_constructed, 'custom constructor called (immutable)');
    }
}

done_testing;
