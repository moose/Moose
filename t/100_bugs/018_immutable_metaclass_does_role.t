#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

BEGIN {
    package MyRole;
    use Moose::Role;

    requires 'foo';

    package MyMetaclass;
    use Moose qw(extends with);
    extends 'Moose::Meta::Class';
       with 'MyRole';
        
    sub foo { 'i am foo' }        
}

{
    package MyClass;
    use metaclass ('MyMetaclass');
    use Moose;
}

my $mc = MyMetaclass->initialize('MyClass');
isa_ok($mc, 'MyMetaclass');

ok($mc->meta->does_role('MyRole'), '... the metaclass does the role');

is(MyClass->meta, $mc, '... these metas are the same thing');
is(MyClass->meta->meta, $mc->meta, '... these meta-metas are the same thing');

my $a = MyClass->new;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );
ok( MyClass->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

diag join ", " => map { $_->name } @{$mc->meta->roles};
diag join ", " => map { $_->name } $mc->meta->calculate_all_roles;

lives_ok {
    MyClass->meta->make_immutable;
} '... make MyClass immutable okay';

diag join ", " => map { $_->name } @{$mc->meta->roles};
diag join ", " => map { $_->name } $mc->meta->calculate_all_roles;

is(MyClass->meta, $mc, '... these metas are still the same thing');
is(MyClass->meta->meta, $mc->meta, '... these meta-metas are the same thing');

ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );
ok( MyClass->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

=pod

MyClass->meta->make_mutable;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

MyMetaclass->meta->make_immutable;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

MyClass->meta->make_immutable;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

