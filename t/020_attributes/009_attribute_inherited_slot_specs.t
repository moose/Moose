#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 83;
use Test::Exception;

BEGIN {
    use_ok('Moose');  
}

{
    package Thing;
    use Moose;
    
    sub hello   { 'Hello World (from Thing)' }
    sub goodbye { 'Goodbye World (from Thing)' }    
    
    package Foo;
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
    has 'gloum' => (is => 'ro', default => sub {[]});  
    
    has 'bling' => (is => 'ro', isa => 'Thing');
    has 'blang' => (is => 'ro', isa => 'Thing', handles => ['goodbye']);         
    
    has 'bunch_of_stuff' => (is => 'rw', isa => 'ArrayRef');

    has 'one_last_one' => (is => 'rw', isa => 'Ref');   
    
    # this one will work here ....
    has 'fail' => (isa => 'CodeRef');
    has 'other_fail';    
    
    package Bar;
    use Moose;
    use Moose::Util::TypeConstraints;
    
    extends 'Foo';

    ::lives_ok {     
        has '+bar' => (default => 'Bar::bar');  
    } '... we can change the default attribute option';        
    
    ::lives_ok {     
        has '+baz' => (isa => 'ArrayRef');        
    } '... we can add change the isa as long as it is a subtype';        
    
    ::lives_ok {     
        has '+foo' => (coerce => 1);    
    } '... we can change/add coerce as an attribute option';            

    ::lives_ok {     
        has '+gorch' => (required => 1); 
    } '... we can change/add required as an attribute option';    
    
    ::lives_ok { 
        has '+gloum' => (lazy => 1);           
    } '... we can change/add lazy as an attribute option';    

    ::lives_ok {
        has '+bunch_of_stuff' => (isa => 'ArrayRef[Int]');        
    } '... extend an attribute with parameterized type';
    
    ::lives_ok {
        has '+one_last_one' => (isa => subtype('Ref', where { blessed $_ eq 'CODE' }));        
    } '... extend an attribute with anon-subtype';    
    
    ::lives_ok {
        has '+one_last_one' => (isa => 'Value');        
    } '... now can extend an attribute with a non-subtype';    

    ::lives_ok {
        has '+bling' => (handles => ['hello']);        
    } '... we can add the handles attribute option';
    
    # this one will *not* work here ....
    ::dies_ok {
        has '+blang' => (handles => ['hello']);        
    } '... we can not alter the handles attribute option';    
    ::lives_ok { 
        has '+fail' => (isa => 'Ref');           
    } '... can now create an attribute with an improper subtype relation';    
    ::dies_ok { 
        has '+other_fail' => (trigger => sub {});           
    } '... cannot create an attribute with an illegal option';    
    ::dies_ok { 
        has '+other_fail' => (weak_ref => 1);           
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
    
    lives_ok { $foo->bunch_of_stuff([qw[one two three]]) } '... Foo::bunch_of_stuff accepts an array of strings';    
    
    lives_ok { $foo->one_last_one(sub { 'Hello World'}) } '... Foo::one_last_one accepts a code ref';        
    
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
    
    lives_ok { $bar->bunch_of_stuff([1, 2, 3]) } '... Bar::bunch_of_stuff accepts an array of ints';        
    dies_ok { $bar->bunch_of_stuff([qw[one two three]]) } '... Bar::bunch_of_stuff does not accept an array of strings';        
    
    my $code_ref = sub { 1 };
    dies_ok { $bar->baz($code_ref) } '... Bar::baz does not accept a code ref';
}

# check some meta-stuff

ok(Bar->meta->has_attribute('foo'), '... Bar has a foo attr');
ok(Bar->meta->has_attribute('bar'), '... Bar has a bar attr');
ok(Bar->meta->has_attribute('baz'), '... Bar has a baz attr');
ok(Bar->meta->has_attribute('gorch'), '... Bar has a gorch attr');
ok(Bar->meta->has_attribute('gloum'), '... Bar has a gloum attr');
ok(Bar->meta->has_attribute('bling'), '... Bar has a bling attr');
ok(Bar->meta->has_attribute('bunch_of_stuff'), '... Bar does have a bunch_of_stuff attr');
ok(!Bar->meta->has_attribute('blang'), '... Bar has a blang attr');
ok(Bar->meta->has_attribute('fail'), '... Bar has a fail attr');
ok(!Bar->meta->has_attribute('other_fail'), '... Bar does not have an other_fail attr');

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
isnt(Foo->meta->get_attribute('gloum'), 
     Bar->meta->get_attribute('gloum'), 
     '... Foo and Bar have different copies of gloum'); 
isnt(Foo->meta->get_attribute('bling'), 
     Bar->meta->get_attribute('bling'), 
     '... Foo and Bar have different copies of bling');              
isnt(Foo->meta->get_attribute('bunch_of_stuff'), 
     Bar->meta->get_attribute('bunch_of_stuff'), 
     '... Foo and Bar have different copies of bunch_of_stuff');     
     
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
   
is(Foo->meta->get_attribute('bunch_of_stuff')->type_constraint->name, 
  'ArrayRef',
  '... Foo::bunch_of_stuff is an ArrayRef');
is(Bar->meta->get_attribute('bunch_of_stuff')->type_constraint->name, 
  'ArrayRef[Int]',
  '... Bar::bunch_of_stuff is an ArrayRef[Int]');
   
ok(!Foo->meta->get_attribute('gloum')->is_lazy, 
   '... Foo::gloum is not a required attr');
ok(Bar->meta->get_attribute('gloum')->is_lazy, 
   '... Bar::gloum is a required attr');   
   
ok(!Foo->meta->get_attribute('foo')->should_coerce, 
  '... Foo::foo should not coerce');
ok(Bar->meta->get_attribute('foo')->should_coerce, 
   '... Bar::foo should coerce');  
   
ok(!Foo->meta->get_attribute('bling')->has_handles, 
   '... Foo::foo should not handles');
ok(Bar->meta->get_attribute('bling')->has_handles, 
   '... Bar::foo should handles');     


