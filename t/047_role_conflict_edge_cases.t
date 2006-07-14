#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Role');    
}

=pod

Check for repeated inheritence causing 
a method conflict (which is not really 
a conflict)

=cut

{
    package Role::Base;
    use Moose::Role;
    
    sub foo { 'Role::Base::foo' }
    
    package Role::Derived1;
    use Moose::Role;  
    
    with 'Role::Base';
    
    package Role::Derived2;
    use Moose::Role; 

    with 'Role::Base';
    
    package My::Test::Class1;
    use Moose;      
    
    ::lives_ok {
        with 'Role::Derived1', 'Role::Derived2';   
    } '... roles composed okay (no conflicts)';
}

ok(Role::Base->meta->has_method('foo'), '... have the method foo as expected');
ok(Role::Derived1->meta->has_method('foo'), '... have the method foo as expected');
ok(Role::Derived2->meta->has_method('foo'), '... have the method foo as expected');
ok(My::Test::Class1->meta->has_method('foo'), '... have the method foo as expected');

is(My::Test::Class1->foo, 'Role::Base::foo', '... got the right value from method');

=pod

Check for repeated inheritence causing 
a attr conflict (which is not really 
a conflict)

=cut

{
    package Role::Base4;
    use Moose::Role;
    
    has 'foo' => (is => 'ro', default => 'Role::Base::foo');
    
    package Role::Derived7;
    use Moose::Role;  
    
    with 'Role::Base4';
    
    package Role::Derived8;
    use Moose::Role; 

    with 'Role::Base4';
    
    package My::Test::Class4;
    use Moose;      
    
    ::lives_ok {
        with 'Role::Derived7', 'Role::Derived8';   
    } '... roles composed okay (no conflicts)';
}

ok(Role::Base4->meta->has_attribute('foo'), '... have the attribute foo as expected');
ok(Role::Derived7->meta->has_attribute('foo'), '... have the attribute foo as expected');
ok(Role::Derived8->meta->has_attribute('foo'), '... have the attribute foo as expected');
ok(My::Test::Class4->meta->has_attribute('foo'), '... have the attribute foo as expected');

is(My::Test::Class4->new->foo, 'Role::Base::foo', '... got the right value from method');
