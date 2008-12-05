#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

=pod

This tests to make sure that the inlined constructor
has all the type constraints in order, even in the 
cases when there is no type constraint available, such 
as with a Class::MOP::Attribute object.

=cut

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    
    coerce 'Int' => from 'Str' => via { length $_ ? $_ : 69 };

    has 'foo' => (is => 'rw', isa => 'Int');    
    has 'baz' => (is => 'rw', isa => 'Int');
    has 'zot' => (is => 'rw', isa => 'Int', init_arg => undef);
    has 'moo' => (is => 'rw', isa => 'Int', coerce => 1, default => '', required => 1);
    has 'boo' => (is => 'rw', isa => 'Int', coerce => 1, builder => '_build_boo', required => 1);

    sub _build_boo { '' }

    Foo->meta->add_attribute(
        Class::MOP::Attribute->new(
            'bar' => (
                accessor => 'bar',
            )
        )
    );
}

for (1..2) {
    my $is_immutable   = Foo->meta->is_immutable;
    my $mutable_string = $is_immutable ? 'immutable' : 'mutable';
    lives_ok {
        my $f = Foo->new(foo => 10, bar => "Hello World", baz => 10, zot => 4);
        is($f->moo, 69, "Type coercion works as expected on default ($mutable_string)");
        is($f->boo, 69, "Type coercion works as expected on builder ($mutable_string)");
    } "... this passes the constuctor correctly ($mutable_string)";

    lives_ok {
        Foo->new(foo => 10, bar => "Hello World", baz => 10, zot => "not an int");
    } "... the constructor doesn't care about 'zot' ($mutable_string)";

    dies_ok {
        Foo->new(foo => "Hello World", bar => 100, baz => "Hello World");
    } "... this fails the constuctor correctly ($mutable_string)";

    Foo->meta->make_immutable(debug => 0) unless $is_immutable;
}



