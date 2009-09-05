#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib', 't/lib';
use Test::More tests => 23;
use Test::Exception;
use MetaTest;

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
}

skip_meta {
   can_ok('Foo', 'meta');
   isa_ok(Foo->meta, 'Moose::Meta::Class');
} 2;


meta_can_ok('Foo', 'meta', '... we got the &meta method');
ok(Foo->isa('Moose::Object'), '... Foo is automagically a Moose::Object');

skip_meta {
   dies_ok {
      Foo->meta->has_method()
   } '... has_method requires an arg';

   dies_ok {
      Foo->meta->has_method('')
   } '... has_method requires an arg';
} 2;
can_ok('Foo', 'does');

skip_meta {
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
} 15;

