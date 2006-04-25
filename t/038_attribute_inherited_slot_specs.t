#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 57;
use Test::Exception;

BEGIN {
    use_ok('Moose');  
}

{
    package Foo;
    use strict;
    use warnings;
    use Moose;
    use Moose::Util::TypeConstraints;
    
    subtype 'FooStr' 
        => as 'Str'
        => where { /Foo/ };
        
    coerce 'FooStr' 
        => from ArrayRef
            => via { 'FooArrayRef' };
    
    has 'bar' => (is => 'ro', isa => 'Str', default => 'Foo::bar');
    has 'baz' => (is => 'rw', isa => 'Ref');   
    has 'foo' => (is => 'rw', isa => 'FooStr');       
    
    has 'gorch' => (is => 'ro');        
    
    # this one will work here ....
    has 'fail' => (isa => 'CodeRef');
    has 'other_fail';    
    
    package Bar;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Foo';
    
    has '+bar' => (default => 'Bar::bar');  
    has '+baz' => (isa     => 'ArrayRef');        
    
    has '+foo'   => (coerce   => 1);    
    has '+gorch' => (required => 1); 
    
    # this one will *not* work here ....
    ::dies_ok { 
        has '+fail' => (isa => 'Ref');           
    } '... cannot create an attribute with an improper subtype relation';    
    ::dies_ok { 
        has '+other_fail' => (trigger => sub {});           
    } '... cannot create an attribute with an illegal option';    
    ::dies_ok { 
        has '+other_fail' => (weak_ref => 1);           
    } '... cannot create an attribute with an illegal option';    
    ::dies_ok { 
        has '+other_fail' => (lazy => 1);           
    } '... cannot create an attribute with an illegal option';    
    
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->foo, undef, '... got the right undef default value');
lives_ok { $foo->foo('FooString') } '... assigned foo correctly';
is($foo->foo, 'FooString', '... got the right value for foo');

dies_ok { $foo->foo([]) } '... foo is not coercing (as expected)';

is($foo->bar, 'Foo::bar', '... got the right default value');
dies_ok { $foo->bar(10) } '... Foo::bar is a read/only attr';

is($foo->baz, undef, '... got the right undef default value');

{
    my $hash_ref = {};
    lives_ok { $foo->baz($hash_ref) } '... Foo::baz accepts hash refs';
    is($foo->baz, $hash_ref, '... got the right value assigned to baz');
    
    my $array_ref = [];
    lives_ok { $foo->baz($array_ref) } '... Foo::baz accepts an array ref';
    is($foo->baz, $array_ref, '... got the right value assigned to baz');

    my $scalar_ref = \(my $var);
    lives_ok { $foo->baz($scalar_ref) } '... Foo::baz accepts scalar ref';
    is($foo->baz, $scalar_ref, '... got the right value assigned to baz');
    
    my $code_ref = sub { 1 };
    lives_ok { $foo->baz($code_ref) } '... Foo::baz accepts a code ref';
    is($foo->baz, $code_ref, '... got the right value assigned to baz');    
}

dies_ok {
    Bar->new;
} '... cannot create Bar without required gorch param';

my $bar = Bar->new(gorch => 'Bar::gorch');
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

is($bar->foo, undef, '... got the right undef default value');
lives_ok { $bar->foo('FooString') } '... assigned foo correctly';
is($bar->foo, 'FooString', '... got the right value for foo');
lives_ok { $bar->foo([]) } '... assigned foo correctly';
is($bar->foo, 'FooArrayRef', '... got the right value for foo');

is($bar->gorch, 'Bar::gorch', '... got the right default value');

is($bar->bar, 'Bar::bar', '... got the right default value');
dies_ok { $bar->bar(10) } '... Bar::bar is a read/only attr';

is($bar->baz, undef, '... got the right undef default value');

{
    my $hash_ref = {};
    dies_ok { $bar->baz($hash_ref) } '... Bar::baz does not accept hash refs';
    
    my $array_ref = [];
    lives_ok { $bar->baz($array_ref) } '... Bar::baz can accept an array ref';
    is($bar->baz, $array_ref, '... got the right value assigned to baz');

    my $scalar_ref = \(my $var);
    dies_ok { $bar->baz($scalar_ref) } '... Bar::baz does not accept a scalar ref';
    
    my $code_ref = sub { 1 };
    dies_ok { $bar->baz($code_ref) } '... Bar::baz does not accept a code ref';
}

# check some meta-stuff

ok(Bar->meta->has_attribute('foo'), '... Bar has a foo attr');
ok(Bar->meta->has_attribute('bar'), '... Bar has a bar attr');
ok(Bar->meta->has_attribute('baz'), '... Bar has a baz attr');
ok(Bar->meta->has_attribute('gorch'), '... Bar has a gorch attr');
ok(!Bar->meta->has_attribute('fail'), '... Bar does not have a fail attr');
ok(!Bar->meta->has_attribute('other_fail'), '... Bar does not have a fail attr');

isnt(Foo->meta->get_attribute('foo'), 
     Bar->meta->get_attribute('foo'), 
     '... Foo and Bar have different copies of foo');
isnt(Foo->meta->get_attribute('bar'), 
     Bar->meta->get_attribute('bar'), 
     '... Foo and Bar have different copies of bar');
isnt(Foo->meta->get_attribute('baz'), 
     Bar->meta->get_attribute('baz'), 
     '... Foo and Bar have different copies of baz');          
isnt(Foo->meta->get_attribute('gorch'), 
     Bar->meta->get_attribute('gorch'), 
     '... Foo and Bar have different copies of gorch');     
     
ok(Bar->meta->get_attribute('bar')->has_type_constraint, 
   '... Bar::bar inherited the type constraint too');
ok(Bar->meta->get_attribute('baz')->has_type_constraint, 
  '... Bar::baz inherited the type constraint too');   

is(Bar->meta->get_attribute('bar')->type_constraint->name, 
   'Str', '... Bar::bar inherited the right type constraint too');

is(Foo->meta->get_attribute('baz')->type_constraint->name, 
  'Ref', '... Foo::baz inherited the right type constraint too');
is(Bar->meta->get_attribute('baz')->type_constraint->name, 
   'ArrayRef', '... Bar::baz inherited the right type constraint too');   
   
ok(!Foo->meta->get_attribute('gorch')->is_required, 
  '... Foo::gorch is not a required attr');
ok(Bar->meta->get_attribute('gorch')->is_required, 
   '... Bar::gorch is a required attr');
   
ok(!Foo->meta->get_attribute('foo')->should_coerce, 
  '... Foo::foo should not coerce');
ok(Bar->meta->get_attribute('foo')->should_coerce, 
   '... Bar::foo should coerce');    


