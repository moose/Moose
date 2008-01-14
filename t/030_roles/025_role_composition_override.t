#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Meta::Role::Application::RoleSummation');    
    use_ok('Moose::Meta::Role::Composite');
}

{
    package Role::Foo;
    use Moose::Role;
    
    override foo => sub { 'Role::Foo::foo' };
    
    package Role::Bar;
    use Moose::Role;

    override bar => sub { 'Role::Bar::bar' };
    
    package Role::FooConflict;
    use Moose::Role;    
    
    override foo => sub { 'Role::FooConflict::foo' };
    
    package Role::FooMethodConflict;
    use Moose::Role;    
    
    sub foo { 'Role::FooConflict::foo' }    
    
    package Role::BarMethodConflict;
    use Moose::Role;
    
    sub bar { 'Role::BarConflict::bar' }
}

# test simple overrides
{
    my $c = Moose::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::Bar->meta,
        ]
    );
    isa_ok($c, 'Moose::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::Bar', '... got the composite role name');    
    
    lives_ok {
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this lives ok';    
    
    is_deeply(
        [ sort $c->get_method_modifier_list('override') ],
        [ 'bar', 'foo' ],
        '... got the right list of methods'
    );
}

# test simple overrides w/ conflicts
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::FooConflict->meta,
            ]
        )
    );
} '... this fails as expected';

# test simple overrides w/ conflicts
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(        
            roles => [
                Role::Foo->meta,
                Role::FooMethodConflict->meta,
            ]
        )
    );
} '... this fails as expected';


# test simple overrides w/ conflicts
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::Bar->meta,            
                Role::FooConflict->meta,         
            ]
        )
    );
} '... this fails as expected';


# test simple overrides w/ conflicts
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(        
            roles => [
                Role::Foo->meta,
                Role::Bar->meta,            
                Role::FooMethodConflict->meta,          
            ]
        )
    );
} '... this fails as expected';
