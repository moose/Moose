#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw[cmpthese];

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    
    has 'baz' => (is => 'rw');
    has 'bar' => (is => 'rw', isa => 'Foo');
    has 'boo' => (is => 'rw', isa => type 'CustomFoo' => where { blessed($_) && $_->isa('Foo') });
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
        'w_custom_constraint' => sub {
            $foo->boo($foo);            
        },        
    }
);

1;