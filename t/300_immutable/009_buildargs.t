#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Foo;
    use Moose;

    has bar => ( is => "rw" );

    sub BUILDARGS {
        my ( $self, @args ) = @_;
        unshift @args, "bar" if @args % 2 == 1;
        return {@args};
    }

    package Bar;
    use Moose;

    extends qw(Foo);

    __PACKAGE__->meta->make_immutable;
}

foreach my $class qw(Foo Bar) {
    is( $class->new->bar, undef, "no args" );
    is( $class->new( bar => 42 )->bar, 42, "normal args" );
    is( $class->new( 37 )->bar, 37, "single arg" );
}
