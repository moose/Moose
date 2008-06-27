#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Foo;
    use Moose;

    has foo => ( is => "ro" );

    __PACKAGE__->meta->make_immutable;

    package Bar;
    use Moose;

    extends qw(Foo);

    around new => sub {
        my $next = shift;
        my ( $self, @args ) = @_;
        $self->$next( foo => 42 );
    };

    __PACKAGE__->meta->make_immutable;

    package Gorch;
    use Moose;

    extends qw(Bar);

    __PACKAGE__->meta->make_immutable;
}

is( Gorch->new->foo, 42, "around new called" );
