use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings;
use overload ();

use lib 't/lib';

use OverloadingTests;
use Overloading::ClassWithCombiningRole;

for my $role (
    qw( Overloading::RoleWithOverloads Overloading::RoleWithoutOverloads )) {

    ok(
        Overloading::ClassWithCombiningRole->DOES($role),
        "Overloading::ClassWithCombiningRole does $role role"
    );
}

OverloadingTests::test_overloading_for_package($_) for qw(
    Overloading::RoleWithOverloads
    Overloading::ClassWithCombiningRole
);

OverloadingTests::test_no_overloading_for_package(
    'Overloading::RoleWithoutOverloads');

OverloadingTests::test_overloading_for_package(
    'Overloading::ClassWithCombiningRole');

done_testing();
