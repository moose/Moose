#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

{
    package HasFoo;
    use Moose::Role;
    has 'foo' => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

}

{
    package My::Metaclass;
    use Moose;
    extends 'Moose::Meta::Class';
    with 'HasFoo';
}

package main;

my $anon;
lives_ok {
    $anon = My::Metaclass->create_anon_class( foo => 'this' );
} 'create anon class';
isa_ok( $anon, 'My::Metaclass' );
cmp_ok( $anon->foo, 'eq', 'this', 'foo is this' );

