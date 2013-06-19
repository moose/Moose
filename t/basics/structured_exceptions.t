#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

{
    like( exception {
	package SubClassNoSuperClass;
	use Moose;
    	extends;
    	  } ,
    	  qr/Must derive at least one class/,
    	  "extends requires at least one argument" );

    isa_ok( exception {
	package SubClassNoSuperClass;
	use Moose;
    	extends;
    	  }, 
	    'Moose::Exception::ExtendsMissingArgs',
	    "extends requires at least one argument");
}

done_testing;
