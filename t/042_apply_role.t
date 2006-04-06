#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;
use Test::Exception;

BEGIN {  
    use_ok('Moose::Role');               
}

{
    package FooRole;
    use strict;
    use warnings;
    use Moose::Role;
    
    has 'bar' => (is => 'rw', isa => 'FooClass');
    has 'baz' => (is => 'ro');    
    
    sub goo { 'FooRole::goo' }
    sub foo { 'FooRole::foo' }
    
    override 'boo' => sub { 'FooRole::boo -> ' . super() };   
    
    around 'blau' => sub {  
        my $c = shift;
        'FooRole::blau -> ' . $c->();
    }; 

    package BarClass;
    use strict;
    use warnings;
    use Moose;
    
    sub boo { 'BarClass::boo' }
    sub foo { 'BarClass::foo' }  # << the role overrides this ...  
    
    package FooClass;
    use strict;
    use warnings;
    use Moose;
    
    extends 'BarClass';
       with 'FooRole';
    
    sub blau { 'FooClass::blau' }

    sub goo { 'FooClass::goo' }  # << overrides the one from the role ... 
}

my $foo_class_meta = FooClass->meta;
isa_ok($foo_class_meta, 'Moose::Meta::Class');

foreach my $method_name (qw(bar baz foo boo blau goo)) {
    ok($foo_class_meta->has_method($method_name), '... FooClass has the method ' . $method_name);    
}

foreach my $attr_name (qw(bar baz)) {
    ok($foo_class_meta->has_attribute($attr_name), '... FooClass has the attribute ' . $attr_name);    
}

my $foo = FooClass->new();
isa_ok($foo, 'FooClass');

can_ok($foo, 'bar');
can_ok($foo, 'baz');
can_ok($foo, 'foo');
can_ok($foo, 'boo');
can_ok($foo, 'goo');
can_ok($foo, 'blau');

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

is($foo->boo, 'FooRole::boo -> BarClass::boo', '... got the right value from ->boo');
is($foo->blau, 'FooRole::blau -> FooClass::blau', '... got the right value from ->blau');

