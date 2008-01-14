#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Meta::Role::Application::RoleSummation');    
    use_ok('Moose::Meta::Role::Composite');
}

{
    package Role::Foo;
    use Moose::Role;
    
    package Role::Bar;
    use Moose::Role;
    
    package Role::ExcludesFoo;
    use Moose::Role;
    excludes 'Role::Foo';
    
    package Role::DoesExcludesFoo;
    use Moose::Role;
    with 'Role::ExcludesFoo';  
    
    package Role::DoesFoo;
    use Moose::Role;
    with 'Role::Foo';    
}

ok(Role::ExcludesFoo->meta->excludes_role('Role::Foo'), '... got the right exclusions');
ok(Role::DoesExcludesFoo->meta->excludes_role('Role::Foo'), '... got the right exclusions');

# test simple exclusion
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::ExcludesFoo->meta,
            ]
        )
    );
} '... this fails as expected';

# test no conflicts
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
    } '... this lives as expected';    
}

# test no conflicts w/exclusion
{
    my $c = Moose::Meta::Role::Composite->new(
        roles => [
            Role::Bar->meta,
            Role::ExcludesFoo->meta,            
        ]
    );
    isa_ok($c, 'Moose::Meta::Role::Composite');

    is($c->name, 'Role::Bar|Role::ExcludesFoo', '... got the composite role name');
    
    lives_ok {
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this lives as expected';    
    
    is_deeply([$c->get_excluded_roles_list], ['Role::Foo'], '... has excluded roles');    
}


# test conflict with an "inherited" exclusion
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::DoesExcludesFoo->meta,
            ]
        )
    );
    
} '... this fails as expected';

# test conflict with an "inherited" exclusion of an "inherited" role
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(        
            roles => [
                Role::DoesFoo->meta,            
                Role::DoesExcludesFoo->meta,
            ]
        )
    );
} '... this fails as expected';


