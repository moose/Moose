#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Meta::Role::Application::RoleSummation');    
    use_ok('Moose::Meta::Role::Composite');
}

{
    package Role::Foo;
    use Moose::Role;    
    requires 'foo';
    
    package Role::Bar;
    use Moose::Role;
    requires 'bar';
    
    package Role::ProvidesFoo;
    use Moose::Role;    
    sub foo { 'Role::ProvidesFoo::foo' }
    
    package Role::ProvidesBar;
    use Moose::Role;    
    sub bar { 'Role::ProvidesBar::bar' }     
}

# test simple requirement
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
    } '... this succeeds as expected';    
    
    is_deeply(
        [ sort $c->get_required_method_list ],
        [ 'bar', 'foo' ],
        '... got the right list of required methods'
    );
}

# test requirement satisfied
{
    my $c = Moose::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::ProvidesFoo->meta,
        ]
    );
    isa_ok($c, 'Moose::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::ProvidesFoo', '... got the composite role name');    
    
    lives_ok { 
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this succeeds as expected';    
    
    is_deeply(
        [ sort $c->get_required_method_list ],
        [],
        '... got the right list of required methods'
    );
}

# test requirement satisfied
{
    my $c = Moose::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::ProvidesFoo->meta,
            Role::Bar->meta,            
        ]
    );
    isa_ok($c, 'Moose::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::ProvidesFoo|Role::Bar', '... got the composite role name');    
    
    lives_ok {
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this succeeds as expected';    
    
    is_deeply(
        [ sort $c->get_required_method_list ],
        [ 'bar' ],
        '... got the right list of required methods'
    );
}

# test requirement satisfied
{
    my $c = Moose::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::ProvidesFoo->meta,
            Role::ProvidesBar->meta,            
            Role::Bar->meta,            
        ]
    );
    isa_ok($c, 'Moose::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::ProvidesFoo|Role::ProvidesBar|Role::Bar', '... got the composite role name');    
    
    lives_ok {
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this succeeds as expected';    
    
    is_deeply(
        [ sort $c->get_required_method_list ],
        [ ],
        '... got the right list of required methods'
    );
}


