#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;

BEGIN {  
    use_ok('Moose::Role');               
}

=pod

NOTE:

Should we be testing here that the has & override
are injecting their methods correctly? In other 
words, should 'has_method' return true for them?

=cut

{
    package FooRole;
    use Moose::Role;
    
    our $VERSION = '0.01';
    
    has 'bar' => (is => 'rw', isa => 'Foo');
    has 'baz' => (is => 'ro');    
    
    sub foo { 'FooRole::foo' }
    sub boo { 'FooRole::boo' }    
   
    ::dies_ok { extends() } '... extends() is not supported';
    ::dies_ok { augment() } '... augment() is not supported';
    ::dies_ok { inner() } '... inner() is not supported';
    ::dies_ok { overrides() } '... overrides() is not supported';
    ::dies_ok { super() } '... super() is not supported';
    ::dies_ok { after() } '... after() is not supported';
    ::dies_ok { before() } '... before() is not supported';
    ::dies_ok { around() } '... around() is not supported';
}

my $foo_role = FooRole->meta;
isa_ok($foo_role, 'Moose::Meta::Role');

isa_ok($foo_role->_role_meta, 'Class::MOP::Class');

is($foo_role->name, 'FooRole', '... got the right name of FooRole');
is($foo_role->version, '0.01', '... got the right version of FooRole');

# methods ...

ok($foo_role->has_method('foo'), '... FooRole has the foo method');
is($foo_role->get_method('foo'), \&FooRole::foo, '... FooRole got the foo method');

isa_ok($foo_role->get_method('foo'), 'Moose::Meta::Role::Method');

ok($foo_role->has_method('boo'), '... FooRole has the boo method');
is($foo_role->get_method('boo'), \&FooRole::boo, '... FooRole got the boo method');

isa_ok($foo_role->get_method('boo'), 'Moose::Meta::Role::Method');

is_deeply(
    [ sort $foo_role->get_method_list() ],
    [ 'boo', 'foo' ],
    '... got the right method list');
    
# attributes ...

is_deeply(
    [ sort $foo_role->get_attribute_list() ],
    [ 'bar', 'baz' ],
    '... got the right attribute list');

ok($foo_role->has_attribute('bar'), '... FooRole does have the bar attribute');

is_deeply(
    $foo_role->get_attribute('bar'),
    { is => 'rw', isa => 'Foo' },
    '... got the correct description of the bar attribute');

ok($foo_role->has_attribute('baz'), '... FooRole does have the baz attribute');

is_deeply(
    $foo_role->get_attribute('baz'),
    { is => 'ro' },
    '... got the correct description of the baz attribute');

