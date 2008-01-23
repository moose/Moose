#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

=pod

This tests to make sure that the inlined constructor
has all the type constraints in order, even in the 
cases when there is no type constraint available, such 
as with a Class::MOP::Attribute object.

=cut

{
    package Foo;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Int');    
    has 'baz' => (is => 'rw', isa => 'Int');
    
    Foo->meta->add_attribute(
        Class::MOP::Attribute->new(
            'bar' => (
                accessor => 'bar',
            )
        )
    );
    
    Foo->meta->make_immutable(debug => 0);
}

lives_ok {
    Foo->new(foo => 10, bar => "Hello World", baz => 10);
} '... this passes the constuctor correctly';

dies_ok {
    Foo->new(foo => "Hello World", bar => 100, baz => "Hello World");
} '... this fails the constuctor correctly';




