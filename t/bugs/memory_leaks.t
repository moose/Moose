use strict;
use warnings;

use Test::Requires {
    'Test::LeakTrace' => '0.01',
};

use Test::More;

use Moose ();
use Moose::Util qw( apply_all_roles );

{
    package MyRole;
    use Moose::Role;
    sub myname { "I'm a role" }
}

no_leaks_ok(
    sub {
        Moose::Meta::Class->create_anon_class->new_object;
    },
    'anonymous class with no roles is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Role->initialize('MyRole2');
    },
    'Moose::Meta::Role->initialize is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Class->create('MyClass2')->new_object;
    },
    'creating named class is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Class->create( 'MyClass', roles => ['MyRole'] );
    },
    'named class with roles is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Role->create( 'MyRole2', roles => ['MyRole'] );
    },
    'named role with roles is leak-free'
);

no_leaks_ok(
    sub {
        my $object = Moose::Meta::Class->create('MyClass2')->new_object;
        apply_all_roles( $object, 'MyRole' );
    },
    'applying role to an instance is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Role->create_anon_role;
    },
    'anonymous role is leak-free'
);

no_leaks_ok(
    sub {
        my $meta = Moose::Meta::Class->create_anon_class;
        $meta->make_immutable;
    },
    'making an anon class immutable is leak-free'
);

done_testing;
