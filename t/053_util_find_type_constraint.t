#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

BEGIN {
	use_ok('Moose::Util::TypeConstraints');
}

foreach my $type_name (qw(
    Any
        Value
            Int
            Str
        Ref
            ScalarRef
            ArrayRef
            HashRef
            CodeRef
            RegexpRef
            Object    
    )) {
    is(find_type_constraint($type_name)->name, 
       $type_name, 
       '... got the right name for ' . $type_name);
}