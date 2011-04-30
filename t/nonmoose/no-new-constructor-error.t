#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package NonMoose;

    sub create { bless {}, shift }

    sub DESTROY { }
}

{
    package Child;
    use Moose;

    extends 'NonMoose';

    {
        my $warning;
        local $SIG{__WARN__} = sub { $warning = $_[0] };
        __PACKAGE__->meta->make_immutable;
        ::like(
            $warning,
            qr/Not inlining.*doesn't contain a constructor named 'new'/,
            "warning when trying to make_immutable without a superclass 'new'"
        );
    }
}

{
    package ChildTwo;
    use Moose;

    extends 'NonMoose';

    {
        my $warning;
        local $SIG{__WARN__} = sub { $warning = $_[0] };
        __PACKAGE__->meta->make_immutable(inline_constructor => 0);
        ::is(
            $warning,
            undef,
            "no warning when trying to make_immutable(inline_constructor => 0) without a superclass 'new'"
        );
    }
}

done_testing;
