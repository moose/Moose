#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use Moose;
}

can_ok('Foo', 'meta');
isa_ok(Foo->meta, 'Moose::Meta::Class');

ok(Foo->meta->has_method('meta'), '... we got the &meta method');
ok(Foo->isa('Moose::Object'), '... Foo is automagically a Moose::Object');

foreach my $function (qw(
						 extends
    	                 has 
	                     before after around
	                     blessed confess
						 type subtype as where
						 coerce from via
						 find_type_constraint
	                     )) {
    ok(!Foo->meta->has_method($function), '... the meta does not treat "' . $function . '" as a method');
}

