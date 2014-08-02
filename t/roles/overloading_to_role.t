use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings;
use overload ();

use lib 't/lib';

use OverloadingTests;
use Overloading::ClassConsumesRoleConsumesOverloads;

for my $role (
    qw( Overloading::RoleWithOverloads Overloading::RoleConsumesOverloads )) {

    ok(
        Overloading::ClassConsumesRoleConsumesOverloads->DOES($role),
        "Overloading::ClassConsumesRoleConsumesOverloads does $role role"
    );
}

OverloadingTests::test_overloading_for_package($_) for qw(
    Overloading::RoleWithOverloads
    Overloading::RoleConsumesOverloads
    Overloading::ClassConsumesRoleConsumesOverloads
);

OverloadingTests::test_overloading_for_object(
    'Overloading::ClassConsumesRoleConsumesOverloads');

# These tests failed on 5.18+ in MXRWO - the key issue was the lack of a
# "fallback" key being passed to overload.pm
{
    package MyRole1;
    use Moose::Role;
    use overload q{""} => '_stringify';
    sub _stringify {__PACKAGE__}
}

{
    package MyRole2;
    use Moose::Role;
    with 'MyRole1';
}

{
    package Class1;
    use Moose;
    with 'MyRole2';
}

is(
    Class1->new . q{},
    'MyRole1',
    'stringification overloading is passed through all roles'
);

done_testing();
