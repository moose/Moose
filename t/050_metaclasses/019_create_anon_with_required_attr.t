#!/usr/bin/perl

# this functionality may be pushing toward parametric roles/classes
# it's off in a corner and may not be that important

use strict;
use warnings;

use Test::More tests => 15;
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
} 'create anon class with required attr';
isa_ok( $anon, 'My::Metaclass' );
cmp_ok( $anon->foo, 'eq', 'this', 'foo is this' );
dies_ok {
    $anon = My::Metaclass->create_anon_class();
} 'failed to create anon class without required attr';

my $meta;
lives_ok {
    $meta
        = My::Metaclass->initialize( 'Class::Name1' => ( foo => 'that' ) );
} 'initialize a class with required attr';
isa_ok( $meta, 'My::Metaclass' );
cmp_ok( $meta->foo,  'eq', 'that',        'foo is that' );
cmp_ok( $meta->name, 'eq', 'Class::Name1', 'for the correct class' );
dies_ok {
    $meta
        = My::Metaclass->initialize( 'Class::Name2' );
} 'failed to initialize a class without required attr';

lives_ok {
    eval qq{
        package Class::Name3;
        use metaclass 'My::Metaclass' => (
            foo => 'another',
        );
        use Moose;
    };
    die $@ if $@;
} 'use metaclass with required attr';
$meta = Class::Name3->meta;
isa_ok( $meta, 'My::Metaclass' );
cmp_ok( $meta->foo,  'eq', 'another',        'foo is another' );
cmp_ok( $meta->name, 'eq', 'Class::Name3', 'for the correct class' );
dies_ok {
    eval qq{
        package Class::Name4;
        use metaclass 'My::Metaclass';
        use Moose;
    };
    die $@ if $@;
} 'failed to use metaclass without required attr';


# how do we pass a required attribute to -traits?
dies_ok {
    eval qq{
        package Class::Name5;
        use Moose -traits => 'HasFoo';
    };
    die $@ if $@;
} 'failed to use trait without required attr';

