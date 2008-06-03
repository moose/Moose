#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;
use Test::Exception;

use Scalar::Util 'isweak';

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use Moose;
    
    eval {
        has 'foo' => (
            reader => 'get_foo',
            writer => 'set_foo',
        );
    };
    ::ok(!$@, '... created the writer method okay');

    eval {
        has 'foo_required' => (
            reader   => 'get_foo_required',
            writer   => 'set_foo_required',
            required => 1,
        );
    };
    ::ok(!$@, '... created the required writer method okay');

    eval {
        has 'foo_int' => (
            reader => 'get_foo_int',
            writer => 'set_foo_int',
            isa    => 'Int',
        );
    };
    ::ok(!$@, '... created the writer method with type constraint okay');    
    
    eval {
        has 'foo_weak' => (
            reader   => 'get_foo_weak',
            writer   => 'set_foo_weak',
            weak_ref => 1
        );
    };
    ::ok(!$@, '... created the writer method with weak_ref okay');    
}

{
    my $foo = Foo->new(foo_required => 'required');
    isa_ok($foo, 'Foo');

    # regular writer

    can_ok($foo, 'set_foo');
    is($foo->get_foo(), undef, '... got an unset value');
    lives_ok {
        $foo->set_foo(100);
    } '... set_foo wrote successfully';
    is($foo->get_foo(), 100, '... got the correct set value');   
    
    ok(!isweak($foo->{foo}), '... it is not a weak reference');             
    
    # required writer
    
    dies_ok {
        Foo->new;
    } '... cannot create without the required attribute';

    can_ok($foo, 'set_foo_required');
    is($foo->get_foo_required(), 'required', '... got an unset value');
    lives_ok {
        $foo->set_foo_required(100);
    } '... set_foo_required wrote successfully';
    is($foo->get_foo_required(), 100, '... got the correct set value');    
    
    dies_ok {
        $foo->set_foo_required();
    } '... set_foo_required died successfully with no value';

    lives_ok {
        $foo->set_foo_required(undef);
    } '... set_foo_required did accept undef';    

    ok(!isweak($foo->{foo_required}), '... it is not a weak reference');        
    
    # with type constraint
    
    can_ok($foo, 'set_foo_int');
    is($foo->get_foo_int(), undef, '... got an unset value');
    lives_ok {
        $foo->set_foo_int(100);
    } '... set_foo_int wrote successfully';
    is($foo->get_foo_int(), 100, '... got the correct set value'); 
    
    dies_ok {
        $foo->set_foo_int("Foo");
    } '... set_foo_int died successfully';   
        
    ok(!isweak($foo->{foo_int}), '... it is not a weak reference');        
        
    # with weak_ref
    
    my $test = [];
    
    can_ok($foo, 'set_foo_weak');
    is($foo->get_foo_weak(), undef, '... got an unset value');
    lives_ok {
        $foo->set_foo_weak($test);
    } '... set_foo_weak wrote successfully';
    is($foo->get_foo_weak(), $test, '... got the correct set value'); 
    
    ok(isweak($foo->{foo_weak}), '... it is a weak reference');
}



