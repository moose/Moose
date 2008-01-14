#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

{
    package My::Role;
    use Moose::Role;

    sub foo { 'Foo::foo' }
    sub bar { 'Foo::bar' }
    sub baz { 'Foo::baz' }
    
    requires 'role_bar';

    package My::Class;
    use Moose;

    ::lives_ok {
        with 'My::Role' => { alias => { bar => 'role_bar' } };
    } '... this succeeds';
    
    package My::Class::Failure;
    use Moose;

    ::throws_ok {
        with 'My::Role' => { alias => { bar => 'role_bar' } };
    } qr/Cannot create a method alias if a local method of the same name exists/, '... this succeeds';    
    
    sub role_bar { 'FAIL' }
}

ok(My::Class->meta->has_method($_), "we have a $_ method") for qw(foo baz bar role_bar);

{
    package My::OtherRole;
    use Moose::Role;

    ::lives_ok {
        with 'My::Role' => { alias => { bar => 'role_bar' } };
    } '... this succeeds';

    sub bar { 'My::OtherRole::bar' }
    
    package My::OtherRole::Failure;
    use Moose::Role;

    ::throws_ok {
        with 'My::Role' => { alias => { bar => 'role_bar' } };
    } qr/Cannot create a method alias if a local method of the same name exists/, '... this succeeds';    
    
    sub role_bar { 'FAIL' }    
}

ok(My::OtherRole->meta->has_method($_), "we have a $_ method") for qw(foo baz role_bar);
ok(My::OtherRole->meta->requires_method('bar'), '... and the &bar method is required');
ok(!My::OtherRole->meta->requires_method('role_bar'), '... and the &role_bar method is not required');

{
    package Foo::Role;
    use Moose::Role;
    
    sub foo { 'Foo::Role::foo' }
    
    package Bar::Role;
    use Moose::Role;
    
    sub foo { 'Bar::Role::foo' }    

    package Baz::Role;
    use Moose::Role;
    
    sub foo { 'Baz::Role::foo' }   
    
    package My::Foo::Class;
    use Moose;
    
    ::lives_ok {
        with 'Foo::Role' => { alias => { 'foo' => 'foo_foo' }, excludes => 'foo' },
             'Bar::Role' => { alias => { 'foo' => 'bar_foo' }, excludes => 'foo' }, 
             'Baz::Role';
    } '... composed our roles correctly';   
    
    package My::Foo::Class::Broken;
    use Moose;
    
    ::throws_ok {
        with 'Foo::Role' => { alias => { 'foo' => 'foo_foo' }, excludes => 'foo' },
             'Bar::Role' => { alias => { 'foo' => 'foo_foo' }, excludes => 'foo' }, 
             'Baz::Role';
    } qr/\'Foo::Role\|Bar::Role\|Baz::Role\' requires the method \'foo_foo\' to be implemented by \'My::Foo::Class::Broken\'/, 
      '... composed our roles correctly';    
}

{
    my $foo = My::Foo::Class->new;
    isa_ok($foo, 'My::Foo::Class');
    can_ok($foo, $_) for qw/foo foo_foo bar_foo/;
    is($foo->foo, 'Baz::Role::foo', '... got the right method');
    is($foo->foo_foo, 'Foo::Role::foo', '... got the right method');    
    is($foo->bar_foo, 'Bar::Role::foo', '... got the right method');        
}

{
    package My::Foo::Role;
    use Moose::Role;

    ::lives_ok {
        with 'Foo::Role' => { alias => { 'foo' => 'foo_foo' }, excludes => 'foo' },
             'Bar::Role' => { alias => { 'foo' => 'bar_foo' }, excludes => 'foo' }, 
             'Baz::Role';
    } '... composed our roles correctly';
}

ok(My::Foo::Role->meta->has_method($_), "we have a $_ method") for qw/foo foo_foo bar_foo/;;
ok(!My::Foo::Role->meta->requires_method('foo'), '... and the &foo method is not required');


{
    package My::Foo::Role::Other;
    use Moose::Role;

    ::lives_ok {
        with 'Foo::Role' => { alias => { 'foo' => 'foo_foo' }, excludes => 'foo' },
             'Bar::Role' => { alias => { 'foo' => 'foo_foo' }, excludes => 'foo' }, 
             'Baz::Role';
    } '... composed our roles correctly';
}

ok(!My::Foo::Role::Other->meta->has_method('foo_foo'), "we dont have a foo_foo method");
ok(My::Foo::Role::Other->meta->requires_method('foo_foo'), '... and the &foo method is required');

