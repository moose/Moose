#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    {
        package Test::Attribute::Inline::Documentation;
        use Moose;

        has 'foo' => (
            documentation => q{
                The 'foo' attribute is my favorite 
                attribute in the whole wide world.
            }
        );
    }
    
    my $foo_attr = Test::Attribute::Inline::Documentation->meta->get_attribute('foo');
    
    ok($foo_attr->has_documentation, '... the foo has docs');
    is($foo_attr->documentation,
            q{
                The 'foo' attribute is my favorite 
                attribute in the whole wide world.
            },
    '... got the foo docs');
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
