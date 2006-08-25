#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

BEGIN {
    use_ok('Moose');
}

{
    package Foo;
    use Moose;
    
    sub greetings {
        "Hello, $_[1]";
    }
    
    method 'greet_world_from' => sub {
        my $from = shift;
        self->greetings("World") . " from $from";
    };    
    
    method 'greet_world_from_me' => sub {
        self->greet_world_from("Stevan");
    };  
    
    no Moose;  
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->greetings('World'), 'Hello, World', '... got the right value from greetings');
is($foo->greet_world_from('Stevan'), 'Hello, World from Stevan', '... got the right value from greet_world_from');
is($foo->greet_world_from_me, 'Hello, World from Stevan', '... got the right value from greet_world');