#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 33;
use Test::Exception;

use Scalar::Util 'isweak';

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use strict;
    use warnings;
    use Moose;
    
    eval {
        has 'foo' => (
            accessor => 'foo',
        );
    };
    ::ok(!$@, '... created the accessor method okay');
    
    eval {
        has 'lazy_foo' => (
            accessor => 'lazy_foo', 
            lazy     => 1, 
            default  => sub { 10 }
        );
    };
    ::ok(!$@, '... created the lazy accessor method okay');              
    

    eval {
        has 'foo_required' => (
            accessor => 'foo_required',
            required => 1,
        );
    };
    ::ok(!$@, '... created the required accessor method okay');

    eval {
        has 'foo_int' => (
            accessor => 'foo_int',
            isa      => 'Int',
        );
    };
    ::ok(!$@, '... created the accessor method with type constraint okay');    
    
    eval {
        has 'foo_weak' => (
            accessor => 'foo_weak',
            weak_ref => 1
        );
    };
    ::ok(!$@, '... created the accessor method with weak_ref okay');    
}

{
    my $foo = Foo->new(foo_required => 'required');
    isa_ok($foo, 'Foo');

    # regular accessor

    can_ok($foo, 'foo');
    is($foo->foo(), undef, '... got an unset value');
    lives_ok {
        $foo->foo(100);
    } '... foo wrote successfully';
    is($foo->foo(), 100, '... got the correct set value');   
    
    ok(!isweak($foo->{foo}), '... it is not a weak reference');   
    
    # required writer
    
    dies_ok {
        Foo->new;
    } '... cannot create without the required attribute';

    can_ok($foo, 'foo_required');
    is($foo->foo_required(), 'required', '... got an unset value');
    lives_ok {
        $foo->foo_required(100);
    } '... foo_required wrote successfully';
    is($foo->foo_required(), 100, '... got the correct set value');    
    
    dies_ok {
        $foo->foo_required(undef);
    } '... foo_required died successfully';    

    ok(!isweak($foo->{foo_required}), '... it is not a weak reference'); 
    
    # lazy
    
    ok(!exists($foo->{lazy_foo}), '... no value in lazy_foo slot');
    
    can_ok($foo, 'lazy_foo');
    is($foo->lazy_foo(), 10, '... got an deferred value');        
    
    # with type constraint
    
    can_ok($foo, 'foo_int');
    is($foo->foo_int(), undef, '... got an unset value');
    lives_ok {
        $foo->foo_int(100);
    } '... foo_int wrote successfully';
    is($foo->foo_int(), 100, '... got the correct set value'); 
    
    dies_ok {
        $foo->foo_int("Foo");
    } '... foo_int died successfully';   
        
    ok(!isweak($foo->{foo_int}), '... it is not a weak reference');        
        
    # with weak_ref
    
    my $test = [];
    
    can_ok($foo, 'foo_weak');
    is($foo->foo_weak(), undef, '... got an unset value');
    lives_ok {
        $foo->foo_weak($test);
    } '... foo_weak wrote successfully';
    is($foo->foo_weak(), $test, '... got the correct set value'); 
    
    ok(isweak($foo->{foo_weak}), '... it is a weak reference');

}



