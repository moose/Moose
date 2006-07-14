#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;
use Test::Exception;

BEGIN {  
    use_ok('Moose::Meta::Role');               
}

{
    package FooRole;
    
    our $VERSION = '0.01';
    
    sub foo { 'FooRole::foo' }
}

my $foo_role = Moose::Meta::Role->new(
    role_name => 'FooRole'
);
isa_ok($foo_role, 'Moose::Meta::Role');

isa_ok($foo_role->_role_meta, 'Class::MOP::Class');

is($foo_role->name, 'FooRole', '... got the right name of FooRole');
is($foo_role->version, '0.01', '... got the right version of FooRole');

# methods ...

ok($foo_role->has_method('foo'), '... FooRole has the foo method');
is($foo_role->get_method('foo'), \&FooRole::foo, '... FooRole got the foo method');

isa_ok($foo_role->get_method('foo'), 'Moose::Meta::Role::Method');

is_deeply(
    [ $foo_role->get_method_list() ],
    [ 'foo' ],
    '... got the right method list');
    
# attributes ...

is_deeply(
    [ $foo_role->get_attribute_list() ],
    [],
    '... got the right attribute list');

ok(!$foo_role->has_attribute('bar'), '... FooRole does not have the bar attribute');

lives_ok {
    $foo_role->add_attribute('bar' => (is => 'rw', isa => 'Foo'));
} '... added the bar attribute okay';

is_deeply(
    [ $foo_role->get_attribute_list() ],
    [ 'bar' ],
    '... got the right attribute list');

ok($foo_role->has_attribute('bar'), '... FooRole does have the bar attribute');

is_deeply(
    $foo_role->get_attribute('bar'),
    { is => 'rw', isa => 'Foo' },
    '... got the correct description of the bar attribute');

lives_ok {
    $foo_role->add_attribute('baz' => (is => 'ro'));
} '... added the baz attribute okay';

is_deeply(
    [ sort $foo_role->get_attribute_list() ],
    [ 'bar', 'baz' ],
    '... got the right attribute list');

ok($foo_role->has_attribute('baz'), '... FooRole does have the baz attribute');

is_deeply(
    $foo_role->get_attribute('baz'),
    { is => 'ro' },
    '... got the correct description of the baz attribute');

lives_ok {
    $foo_role->remove_attribute('bar');
} '... removed the bar attribute okay';

is_deeply(
    [ $foo_role->get_attribute_list() ],
    [ 'baz' ],
    '... got the right attribute list');

ok(!$foo_role->has_attribute('bar'), '... FooRole does not have the bar attribute');
ok($foo_role->has_attribute('baz'), '... FooRole does still have the baz attribute');

