#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

BEGIN {
    use_ok('Moose');
}

## Mixin a class without a superclass.
{
    package FooMixin;   
    use Moose;
    sub foo { 'FooMixin::foo' }    

    package Foo;
    use Moose;
    
    with 'FooMixin';
    
    sub new { (shift)->meta->new_object(@_) }
}

my $foo = Foo->new();
isa_ok($foo, 'Foo');

can_ok($foo, 'foo');
is($foo->foo, 'FooMixin::foo', '... got the right value from the mixin method');

## Mixin a class who shares a common ancestor
{   
    package Baz;
    use Moose;
    extends 'Foo';    
    
    sub baz { 'Baz::baz' }    	

    package Bar;
    use Moose;
    extends 'Foo';

    package Foo::Baz;
    use Moose;
    extends 'Foo';    
	eval { with 'Baz' };
	::ok(!$@, '... the classes superclass must extend a subclass of the superclass of the mixins');

}

my $foo_baz = Foo::Baz->new();
isa_ok($foo_baz, 'Foo::Baz');
isa_ok($foo_baz, 'Foo');

can_ok($foo_baz, 'baz');
is($foo_baz->baz(), 'Baz::baz', '... got the right value from the mixin method');

{
	package Foo::Bar;
	use Moose;
    extends 'Foo', 'Bar';	

    package Foo::Bar::Baz;
    use Moose;
    extends 'Foo::Bar';    
	eval { with 'Baz' };
	::ok(!$@, '... the classes superclass must extend a subclass of the superclass of the mixins');
}

my $foo_bar_baz = Foo::Bar::Baz->new();
isa_ok($foo_bar_baz, 'Foo::Bar::Baz');
isa_ok($foo_bar_baz, 'Foo::Bar');
isa_ok($foo_bar_baz, 'Foo');
isa_ok($foo_bar_baz, 'Bar');

can_ok($foo_bar_baz, 'baz');
is($foo_bar_baz->baz(), 'Baz::baz', '... got the right value from the mixin method');

