#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw[cmpthese];

=pod

This benchmark compares the overhead of a 
auto-created type constraint vs. none at 
all vs. a custom-created type.

=cut

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    
    has 'baz' => (is => 'rw');
    has 'bar' => (is => 'rw', isa => 'Foo');
}

my $foo = Foo->new;

cmpthese(200_000, 
    {
        'w/out_constraint' => sub {
            $foo->baz($foo);
        },
        'w_constraint' => sub {
            $foo->bar($foo);            
        },
    }
);

1;