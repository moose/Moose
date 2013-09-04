use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Meta::Role::Application::RoleSummation;
use Moose::Meta::Role::Composite;

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

    is( exception {
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    }, undef, '... this lives ok' );

    is_deeply(
        [ sort $c->get_method_modifier_list('override') ],
        [ 'bar', 'foo' ],
        '... got the right list of methods'
    );
}

# test simple overrides w/ conflicts
isnt( exception {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::FooConflict->meta,
            ]
        )
    );
}, undef, '... this fails as expected' );

# test simple overrides w/ conflicts
isnt( exception {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::FooMethodConflict->meta,
            ]
        )
    );
}, undef, '... this fails as expected' );


# test simple overrides w/ conflicts
isnt( exception {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::Bar->meta,
                Role::FooConflict->meta,
            ]
        )
    );
}, undef, '... this fails as expected' );


# test simple overrides w/ conflicts
isnt( exception {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::Bar->meta,
                Role::FooMethodConflict->meta,
            ]
        )
    );
}, undef, '... this fails as expected' );

{
    {
        package Foo;
        use Moose::Role;

        override test => sub { print "override test in Foo" };
    }

    my $exception = exception {
        {
            package Bar;
            use Moose::Role;

            override test => sub { print "override test in Bar" };
            with 'Foo';
        }
    };

    like(
        $exception,
        qr/\QRole 'Foo' has encountered an 'override' method conflict during composition (Two 'override' methods of the same name encountered). This is fatal error./,
        "Foo & Bar, both roles are overriding test method");
}

{
    {
        package Role::A;
        use Moose::Role;

        override a_method => sub { "a method in A" };
    }

    {
        package Role::B;
        use Moose::Role;
        with 'Role::A';
    }

    {
        package Role::C;
        use Moose::Role;
        with 'Role::A'
    }

    my $exception = exception {
        {
            package Role::D;
            use Moose::Role;
            with 'Role::B';
            with 'Role::C';
        }
    };

    is( $exception, undef, "this works fine");
}

done_testing;
