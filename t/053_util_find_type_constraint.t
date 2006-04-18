#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;

BEGIN {
	use_ok('Moose::Util::TypeConstraints');
}

foreach my $type_name (qw(
    Any
        Bool
        Value
            Int
            Str
        Ref
            ScalarRef
            CollectionRef
                ArrayRef
                HashRef
            CodeRef
            RegexpRef
            Object    
                Role
    )) {
    is(find_type_constraint($type_name)->name, 
       $type_name, 
       '... got the right name for ' . $type_name);
}