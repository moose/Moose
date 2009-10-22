#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use Moose::Meta::Role::Application::RoleSummation;
use Moose::Meta::Role::Composite;

{
    package Role::Foo;
    use Moose::Role;
    requires_attr 'foo';

    package Role::Bar;
    use Moose::Role;
    requires_attr 'bar';

    package Role::ProvidesFoo;
    use Moose::Role;
    has 'foo' => (is => 'ro');

    package Role::ProvidesBar;
    use Moose::Role;
    has 'bar' => (is => 'ro');
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
        [ sort $c->get_required_attribute_list ],
        [ 'bar', 'foo' ],
        '... got the right list of required attributes'
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
        [ sort $c->get_required_attribute_list ],
        [ 'FAIL' ],
        '... got the right list of required attributes'
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
        [ sort $c->get_required_attribute_list ],
        [ 'bar', ],
        '... got the right list of required attributes'
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
        [ sort $c->get_required_attribute_list ],
        [ 'FAIL' ],
        '... got the right list of required attributes'
    );
}


