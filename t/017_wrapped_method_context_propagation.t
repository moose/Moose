#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Moose');
}

{
    package TouchyBase;
    use Moose;

    has string_ref => ( is => 'rw', default => sub { my $x = "moose fruit"; \$x } );
    has x => ( is => 'rw', default => 0 );

    sub inc { $_[0]->x( 1 + $_[0]->x ) }

    sub scalar_or_array {
        wantarray ? (qw/a b c/) : "x";
    }

    sub array_arity {
        split(/\s+/,"foo bar gorch baz la");
    }

    sub void {
        die "this must be void context" if defined wantarray;
    }

    sub substr_lvalue : lvalue {
        my $self = shift;
        my $string_ref = $self->string_ref;
        my $lvalue_ref = \substr($$string_ref, 0, 5);
        $$lvalue_ref;
    }

    package AfterSub;
    use Moose;

    extends "TouchyBase";

    after qw/scalar_or_array array_arity void substr_lvalue/ => sub {
        my $self = shift;
        $self->inc;        
    }
}

my $base = TouchyBase->new;
my $after = AfterSub->new;

foreach my $obj ( $base, $after ) {
    my $class = ref $obj;
    my @array = $obj->scalar_or_array;
    my $scalar = $obj->scalar_or_array;

    is_deeply(\@array, [qw/a b c/], "array context ($class)");
    is($scalar, "x", "scalar context ($class)");

    {
        local $@;
        eval { $obj->void };
        ok( !$@, "void context ($class)" );
    }
}

