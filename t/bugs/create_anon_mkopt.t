use strict;
use warnings;

use Test::More;

use Moose::Meta::Class;

{
    package Class;
    use Moose;

    package Foo;
    use Moose::Role;

    package Bar;
    use Moose::Role;
}

{
    my $class_and_roles_1 = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        roles        => ['Foo', 'Bar'],
        cache        => 1,
    );

    # Our handling of roles in the Moose::Meta::Class->_anon_cache_key()
    # method was broken because we were trying to use mkopt incorrectly. This
    # was triggered by passing a list where a role name is followed by a role
    # object. Prior to the bug fix this would have died with an error saying
    # 'Roles with parameters cannot be cached ...'
    my $class_and_roles_2 = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        roles        => [ 'Foo', Bar->meta ],
        cache        => 1,
    );

    is(
        $class_and_roles_1->name,
        $class_and_roles_2->name,
        'caching works when roles are given as a mix of names and role objects'
    );
}

done_testing();
