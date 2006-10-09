#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
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
