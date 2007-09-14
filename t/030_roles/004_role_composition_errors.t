#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN {  
    use_ok('Moose');               
}

{
    package Foo::Role;
    use Moose::Role;
    
    requires 'foo';
}

is_deeply(
    [ sort Foo::Role->meta->get_required_method_list ],
    [ 'foo' ],
    '... the Foo::Role has a required method (foo)');

# classes which does not implement required method
{
    package Foo::Class;
    use Moose;
    
    ::dies_ok { with('Foo::Role') } '... no foo method implemented by Foo::Class';
}

# class which does implement required method
{
    package Bar::Class;
    use Moose;
    
    ::dies_ok  { with('Foo::Class') } '... cannot consume a class, it must be a role';
    ::lives_ok { with('Foo::Role')  } '... has a foo method implemented by Bar::Class';
    
    sub foo { 'Bar::Class::foo' }
}

# role which does implement required method
{
    package Bar::Role;
    use Moose::Role;
    
    ::lives_ok { with('Foo::Role') } '... has a foo method implemented by Bar::Role';
    
    sub foo { 'Bar::Role::foo' }
}

is_deeply(
    [ sort Bar::Role->meta->get_required_method_list ],
    [],
    '... the Bar::Role has not inherited the required method from Foo::Role');

# role which does not implement required method
{
    package Baz::Role;
    use Moose::Role;
    
    ::lives_ok { with('Foo::Role') } '... no foo method implemented by Baz::Role';
}

is_deeply(
    [ sort Baz::Role->meta->get_required_method_list ],
    [ 'foo' ],
    '... the Baz::Role has inherited the required method from Foo::Role');
    
# classes which does not implement required method
{
    package Baz::Class;
    use Moose;

    ::dies_ok { with('Baz::Role') } '... no foo method implemented by Baz::Class2';
}

# class which does implement required method
{
    package Baz::Class2;
    use Moose;

    ::lives_ok { with('Baz::Role') } '... has a foo method implemented by Baz::Class2';

    sub foo { 'Baz::Class2::foo' }
}    
    

