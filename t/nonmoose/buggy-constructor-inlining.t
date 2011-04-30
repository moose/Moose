#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

my ($Foo, $Bar, $Baz);
{
    package Foo;

    sub new { $Foo++; bless {}, shift }
}

{
    package Bar;
    use Moose;

    extends 'Foo';

    sub BUILD { $Bar++ }

    __PACKAGE__->meta->make_immutable;
}

{
    package Baz;
    use Moose;

    extends 'Bar';

    sub BUILD { $Baz++ }
}

with_immutable {
    ($Foo, $Bar, $Baz) = (0, 0, 0);
    Baz->new;
    is($Foo, 1, "Foo->new is called once");
    is($Bar, 1, "Bar->BUILD is called once");
    is($Baz, 1, "Baz->BUILD is called once");
} 'Baz';

done_testing;
