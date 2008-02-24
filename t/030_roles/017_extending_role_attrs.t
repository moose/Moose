#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

=pod

This basically just makes sure that using +name 
on role attributes works right. It is pretty simple
test really, but I wanted to have one since we are 
officially supporting the feature now.

=cut

{
    package Foo::Role;
    use Moose::Role;
    
    has 'bar' => (
        is      => 'rw',
        isa     => 'Int',   
        default => sub { 10 },
    );
    
    package Foo;
    use Moose;
    
    with 'Foo::Role';
    
    ::lives_ok {
        has '+bar' => (default => sub { 100 });
    } '... extended the attribute successfully';  
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->bar, 100, '... got the extended attribute');

