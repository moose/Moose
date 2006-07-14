#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 33;
use Test::Exception;

BEGIN {  
    use_ok('Moose::Role');               
}



{
    package FooRole;
    use Moose::Role;
    
    has 'bar' => (is => 'rw', isa => 'FooClass');
    has 'baz' => (is => 'ro');    
    
    sub goo { 'FooRole::goo' }
    sub foo { 'FooRole::foo' }

    package BarClass;
    use Moose;
    
    sub boo { 'BarClass::boo' }
    sub foo { 'BarClass::foo' }  # << the role overrides this ...  
    
    package FooClass;
    use Moose;
    
    extends 'BarClass';
       with 'FooRole';

    sub goo { 'FooClass::goo' }  # << overrides the one from the role ... 
}

my $foo_class_meta = FooClass->meta;
isa_ok($foo_class_meta, 'Moose::Meta::Class');

dies_ok {
    $foo_class_meta->does_role()
} '... does_role requires a role name';

dies_ok {
    $foo_class_meta->apply_role()
} '... apply_role requires a role';

dies_ok {
    $foo_class_meta->apply_role(bless({} => 'Fail'))
} '... apply_role requires a role';

ok($foo_class_meta->does_role('FooRole'), '... the FooClass->meta does_role FooRole');
ok(!$foo_class_meta->does_role('OtherRole'), '... the FooClass->meta !does_role OtherRole');

foreach my $method_name (qw(bar baz foo goo)) {
    ok($foo_class_meta->has_method($method_name), '... FooClass has the method ' . $method_name);    
}

foreach my $attr_name (qw(bar baz)) {
    ok($foo_class_meta->has_attribute($attr_name), '... FooClass has the attribute ' . $attr_name);    
}

can_ok('FooClass', 'does');
ok(FooClass->does('FooRole'), '... the FooClass does FooRole');
ok(!FooClass->does('OtherRole'), '... the FooClass does not do OtherRole');

my $foo = FooClass->new();
isa_ok($foo, 'FooClass');

can_ok($foo, 'does');
ok($foo->does('FooRole'), '... an instance of FooClass does FooRole');
ok(!$foo->does('OtherRole'), '... and instance of FooClass does not do OtherRole');

can_ok($foo, 'bar');
can_ok($foo, 'baz');
can_ok($foo, 'foo');
can_ok($foo, 'goo');

is($foo->foo, 'FooRole::foo', '... got the right value of foo');
is($foo->goo, 'FooClass::goo', '... got the right value of goo');

ok(!defined($foo->baz), '... $foo->baz is undefined');
ok(!defined($foo->bar), '... $foo->bar is undefined');

dies_ok {
    $foo->baz(1)
} '... baz is a read-only accessor';

dies_ok {
    $foo->bar(1)
} '... bar is a read-write accessor with a type constraint';

my $foo2 = FooClass->new();
isa_ok($foo2, 'FooClass');

lives_ok {
    $foo->bar($foo2)
} '... bar is a read-write accessor with a type constraint';

is($foo->bar, $foo2, '... got the right value for bar now');


