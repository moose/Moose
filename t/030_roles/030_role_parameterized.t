#!/usr/bin/perl

use strict;
use warnings;

use Test::More skip_all => 'The feature this test exercises is not yet written';
use Test::Exception;


{
    package Scalar;
    use Moose::Role; 
    
    BEGIN { parameter T => { isa => 'Moose::Meta::TypeConstraint' } };

    has 'val' => (is => 'ro', isa => T);
    
    requires 'eq';
    
    sub not_eq { ! (shift)->eq(shift) }
}

is_deeply(
    Scalar->meta->parameters,
    { T => { isa => 'Moose::Meta::TypeConstraint' } },
    '... got the right parameters in the role'
);

{
    package Integers;
    use Moose;
    use Moose::Util::TypeConstraints;

    with Scalar => { T => find_type_constraint('Int') };
    
    sub eq { shift == shift }
}
