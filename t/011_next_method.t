#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use Moose;
    
    sub hello {
        return 'Foo::hello';
    }
    
    package Bar;
    use Moose;
    
    extends 'Foo';
    
    sub hello {
        return 'Bar::hello -> ' . next_method();
    }
    
    package Baz;
    use Moose;
    
    extends 'Bar';
    
    sub hello {
        return 'Baz::hello -> ' . next_method();
    }  
    
    sub goodbye {
        return 'Baz::goodbye -> ' . next_method();
    }      
}

my $baz = Baz->new;
isa_ok($baz, 'Baz');

is($baz->hello, 'Baz::hello -> Bar::hello -> Foo::hello', '... next_method did the right thing');

dies_ok {
    $baz->goodbye
} '... no next method found, so we die';

