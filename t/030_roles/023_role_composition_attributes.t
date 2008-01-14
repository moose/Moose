#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Meta::Role::Application::RoleSummation');    
    use_ok('Moose::Meta::Role::Composite');
}

{
    package Role::Foo;
    use Moose::Role;    
    has 'foo' => (is => 'rw');
    
    package Role::Bar;
    use Moose::Role;
    has 'bar' => (is => 'rw');
    
    package Role::FooConflict;
    use Moose::Role;    
    has 'foo' => (is => 'rw');
    
    package Role::BarConflict;
    use Moose::Role;
    has 'bar' => (is => 'rw');
    
    package Role::AnotherFooConflict;
    use Moose::Role;    
    with 'Role::FooConflict';
}

# test simple attributes
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
        [ sort $c->get_attribute_list ],
        [ 'bar', 'foo' ],
        '... got the right list of attributes'
    );
}

# test simple conflict
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

# test complex conflict
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::Bar->meta,            
                Role::FooConflict->meta,
                Role::BarConflict->meta,            
            ]
        )
    );
} '... this fails as expected';

# test simple conflict
dies_ok {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::AnotherFooConflict->meta,
            ]
        )
    );
} '... this fails as expected';

