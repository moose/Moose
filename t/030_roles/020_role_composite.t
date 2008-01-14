#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
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

    package Role::Baz;
    use Moose::Role;      
    
    package Role::Gorch;
    use Moose::Role;       
}

{
    my $c = Moose::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::Bar->meta,
            Role::Baz->meta,            
        ]
    );
    isa_ok($c, 'Moose::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::Bar|Role::Baz', '... got the composite role name');

    is_deeply($c->get_roles, [
        Role::Foo->meta,
        Role::Bar->meta,
        Role::Baz->meta,        
    ], '... got the right roles');
    
    ok($c->does_role($_), '... our composite does the role ' . $_)
        for qw(
            Role::Foo
            Role::Bar
            Role::Baz            
        );
    
    lives_ok {
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this composed okay';   
    
    ##... now nest 'em
    { 
        my $c2 = Moose::Meta::Role::Composite->new(
            roles => [
                $c,
                Role::Gorch->meta,
            ]
        );
        isa_ok($c2, 'Moose::Meta::Role::Composite');

        is($c2->name, 'Role::Foo|Role::Bar|Role::Baz|Role::Gorch', '... got the composite role name');

        is_deeply($c2->get_roles, [
            $c,
            Role::Gorch->meta,  
        ], '... got the right roles');

        ok($c2->does_role($_), '... our composite does the role ' . $_)
            for qw(
                Role::Foo
                Role::Bar
                Role::Baz     
                Role::Gorch                        
            );     
    }
}
