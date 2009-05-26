#!perl

use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Moose;
}


plan tests => scalar ( my @universal_methods = qw/isa can VERSION/ );

my $foo = Foo->new;

TODO: {
    local $TODO = 'UNIVERSAL methods should be available';

    for my $method ( @universal_methods ) {
       ok $foo->meta->find_method_by_name($method), "has UNIVERSAL method $method";
    }
};
