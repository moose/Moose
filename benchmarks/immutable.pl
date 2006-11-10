#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util 'blessed';
use Benchmark qw[cmpthese];

use Moose::Util::TypeConstraints;

{
    package Foo;
    use Moose;
    Foo->meta->make_immutable(debug => 0);
}

coerce 'Foo'
    => from 'ArrayRef'
    => via { Foo->new(@{$_}) };

{
    package Foo::Normal;
    use Moose;

    has 'default'         => (is => 'rw', default => 10);
    has 'default_sub'     => (is => 'rw', default => sub { [] });        
    has 'lazy'            => (is => 'rw', default => 10, lazy => 1);
    has 'required'        => (is => 'rw', required => 1);    
    has 'weak_ref'        => (is => 'rw', weak_ref => 1);    
    has 'type_constraint' => (is => 'rw', isa => 'Foo');    
    has 'coercion'        => (is => 'rw', isa => 'Foo', coerce => 1);    
    
}

{
    package Foo::Immutable;
    use Moose;
    
    has 'default'         => (is => 'rw', default => 10);
    has 'default_sub'     => (is => 'rw', default => sub { [] });        
    has 'lazy'            => (is => 'rw', default => 10, lazy => 1);
    has 'required'        => (is => 'rw', required => 1);    
    has 'weak_ref'        => (is => 'rw', weak_ref => 1);    
    has 'type_constraint' => (is => 'rw', isa => 'Foo');    
    has 'coercion'        => (is => 'rw', isa => 'Foo', coerce => 1);
    
    sub BUILD {
        # ...
    }
    
    Foo::Immutable->meta->make_immutable(debug => 1);
}

#__END__

my $foo = Foo->new;

cmpthese(500, 
    {
        'normal' => sub {
            Foo::Normal->new(
                required        => 'BAR',
                type_constraint => $foo,
                coercion        => [],
                weak_ref        => {},
            );
        },
        'immutable' => sub {
            Foo::Immutable->new(
                required        => 'BAR',
                type_constraint => $foo,
                coercion        => [],
                weak_ref        => {},                
            );
        },
    }
);