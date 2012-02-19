use strict;
use warnings;

use Test::Requires {
    'Test::LeakTrace' => '0.01',
};

use Test::More;

use Moose;

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
        Moose::Meta::Class->create( 'MyClass', roles => ['MyRole'] )
            ->new_object;
    },
    'named class with roles is leak-free'
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
        $meta->new_object;
    },
    'making an anon class immutable is leak-free'
);

done_testing;
