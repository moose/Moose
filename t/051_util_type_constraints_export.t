#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN {
	use_ok('Moose::Util::TypeConstraints', ('Foo'));
}

{
    package Foo;

	eval {
		type MyRef => where { ref($_) };
	};
	::ok(!$@, '... successfully exported &type to Foo package');
	
	eval {
		subtype MyArrayRef 
			=> as MyRef 
			=> where { ref($_) eq 'ARRAY' };
	};
	::ok(!$@, '... successfully exported &subtype to Foo package');	
	
	::ok(MyRef({}), '... Ref worked correctly');
	::ok(MyArrayRef([]), '... ArrayRef worked correctly');	
}