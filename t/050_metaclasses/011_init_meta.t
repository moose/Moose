#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose ();


{ package Foo; }

my $meta = Moose::init_meta('Foo');

ok( Foo->isa('Moose::Object'), '... Foo isa Moose::Object');
isa_ok( $meta, 'Moose::Meta::Class' );
isa_ok( Foo->meta, 'Moose::Meta::Class' );

is($meta, Foo->meta, '... our metas are the same');

done_testing;
