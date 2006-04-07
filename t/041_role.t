#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN {  
    use_ok('Moose::Role');               
}

{
    package FooRole;
    
    use strict;
    use warnings;
    use Moose::Role;
    
    our $VERSION = '0.01';
    
    has 'bar' => (is => 'rw', isa => 'Foo');
    has 'baz' => (is => 'ro');    
    
    sub foo { 'FooRole::foo' }
    
    before 'boo' => sub { "FooRole::boo:before" };
}

my $foo_role = FooRole->meta;
isa_ok($foo_role, 'Moose::Meta::Role');

isa_ok($foo_role->role_meta, 'Class::MOP::Class');

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

# method modifiers

ok($foo_role->has_method_modifier('before' => 'boo'), '... now we have a boo:before modifier');
is($foo_role->get_method_modifier('before' => 'boo')->(), 
    "FooRole::boo:before", 
    '... got the right method back');

is_deeply(
    [ $foo_role->get_method_modifier_list('before') ],
    [ 'boo' ],
    '... got the right list of before method modifiers');

