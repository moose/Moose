#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

{

    package Foo;
    use Moose;

    has 'foo' => ( is => 'rw', default => q{'} );
    has 'bar' => ( is => 'rw', default => q{\\} );
    has 'baz' => ( is => 'rw', default => q{"} );
    has 'buz' => ( is => 'rw', default => q{"'\\} );
    has 'faz' => ( is => 'rw', default => qq{\0} );

    ::lives_ok {  __PACKAGE__->meta->make_immutable }
        'no errors making a package immutable when it has default values that could break quoting';
}

my $foo = Foo->new;
is( $foo->foo, q{'},
    'default value for foo attr' );
is( $foo->bar, q{\\},
    'default value for bar attr' );
is( $foo->baz, q{"},
    'default value for baz attr' );
is( $foo->buz, q{"'\\},
    'default value for buz attr' );
is( $foo->faz, qq{\0},
    'default value for faz attr' );


# Lazy attrs were never broken, but it doesn't hurt to test that they
# won't be broken by any future changes.
{

    package Bar;
    use Moose;

    has 'foo' => ( is => 'rw', default => q{'}, lazy => 1 );
    has 'bar' => ( is => 'rw', default => q{\\}, lazy => 1 );
    has 'baz' => ( is => 'rw', default => q{"}, lazy => 1 );
    has 'buz' => ( is => 'rw', default => q{"'\\}, lazy => 1 );
    has 'faz' => ( is => 'rw', default => qq{\0}, lazy => 1 );

    ::lives_ok {  __PACKAGE__->meta->make_immutable }
        'no errors making a package immutable when it has lazy default values that could break quoting';
}

my $bar = Bar->new;
is( $bar->foo, q{'},
    'default value for foo attr' );
is( $bar->bar, q{\\},
    'default value for bar attr' );
is( $bar->baz, q{"},
    'default value for baz attr' );
is( $bar->buz, q{"'\\},
    'default value for buz attr' );
is( $bar->faz, qq{\0},
    'default value for faz attr' );
