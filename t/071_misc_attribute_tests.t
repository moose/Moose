#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    {
        package Test::TheDefaultFor::ArrayRef::and::HashRef;
        use Moose;
    
        has 'array_ref' => (is => 'rw', isa => 'ArrayRef');
        has 'hash_ref'  => (is => 'rw', isa => 'HashRef');    

    }

    my $test = Test::TheDefaultFor::ArrayRef::and::HashRef->new;
    isa_ok($test, 'Test::TheDefaultFor::ArrayRef::and::HashRef');

    is_deeply($test->array_ref, [], '.... got the right default value');
    is_deeply($test->hash_ref,  {}, '.... got the right default value');

    my $test2 = Test::TheDefaultFor::ArrayRef::and::HashRef->new(
        array_ref => [ 1, 2, [] ],
        hash_ref  => { one => 1, two => 2, three => {} },
    );
    isa_ok($test2, 'Test::TheDefaultFor::ArrayRef::and::HashRef');

    is_deeply($test2->array_ref, [ 1, 2, [] ], '.... got the right default value');
    is_deeply($test2->hash_ref,  { one => 1, two => 2, three => {} }, '.... got the right default value');
}

{
    {
        package Test::For::Lazy::TypeConstraint;
        use Moose;
        use Moose::Util::TypeConstraints;

        has 'bad_lazy_attr' => (
            is => 'rw',
            isa => 'ArrayRef',
            lazy => 1, 
            default => sub { "test" },
        );
        
        has 'good_lazy_attr' => (
            is => 'rw',
            isa => 'ArrayRef',
            lazy => 1, 
            default => sub { [] },
        );        

    }

    my $test = Test::For::Lazy::TypeConstraint->new;
    isa_ok($test, 'Test::For::Lazy::TypeConstraint');
    
    dies_ok {
        $test->bad_lazy_attr;
    } '... this does not work';
    
    lives_ok {
        $test->good_lazy_attr;
    } '... this does not work';    
}
