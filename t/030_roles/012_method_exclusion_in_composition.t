#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
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

    package My::Class;
    use Moose;

    with 'My::Role' => { excludes => 'bar' };
}

ok(My::Class->meta->has_method($_), "we have a $_ method") for qw(foo baz);
ok(!My::Class->meta->has_method('bar'), '... but we excluded bar');

{
    package My::OtherRole;
    use Moose::Role;

    with 'My::Role' => { excludes => 'foo' };

    sub foo { 'My::OtherRole::foo' }
    sub bar { 'My::OtherRole::bar' }
}

ok(My::OtherRole->meta->has_method($_), "we have a $_ method") for qw(foo bar baz);

ok(!My::OtherRole->meta->requires_method('foo'), '... and the &foo method is not required');
ok(My::OtherRole->meta->requires_method('bar'), '... and the &bar method is required');

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
        with 'Foo::Role' => { excludes => 'foo' },
             'Bar::Role' => { excludes => 'foo' }, 
             'Baz::Role';
    } '... composed our roles correctly';
    
    package My::Foo::Class::Broken;
    use Moose;
    
    ::throws_ok {
        with 'Foo::Role',
             'Bar::Role' => { excludes => 'foo' }, 
             'Baz::Role';
    } qr/\'Foo::Role\|Bar::Role\|Baz::Role\' requires the method \'foo\' to be implemented by \'My::Foo::Class::Broken\'/, 
      '... composed our roles correctly';    
}

{
    my $foo = My::Foo::Class->new;
    isa_ok($foo, 'My::Foo::Class');
    can_ok($foo, 'foo');
    is($foo->foo, 'Baz::Role::foo', '... got the right method');
}

{
    package My::Foo::Role;
    use Moose::Role;

    ::lives_ok {
        with 'Foo::Role' => { excludes => 'foo' },
             'Bar::Role' => { excludes => 'foo' }, 
             'Baz::Role';
    } '... composed our roles correctly';
}

ok(My::Foo::Role->meta->has_method('foo'), "we have a foo method");
ok(!My::Foo::Role->meta->requires_method('foo'), '... and the &foo method is not required');

{
    package My::Foo::Role::Other;
    use Moose::Role;

    ::lives_ok {
        with 'Foo::Role',
             'Bar::Role' => { excludes => 'foo' }, 
             'Baz::Role';
    } '... composed our roles correctly';
}

ok(!My::Foo::Role::Other->meta->has_method('foo'), "we dont have a foo method");
ok(My::Foo::Role::Other->meta->requires_method('foo'), '... and the &foo method is required');



