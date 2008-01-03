#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
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





