use strict;
use warnings;

use Test::More 0.96;
use Test::Warnings;
use overload ();

use lib 't/lib';

use OverloadingTests;
use Overloading::CombiningClass;

for my $role (
    qw( Overloading::RoleWithOverloads Overloading::RoleWithoutOverloads )) {

    ok(
        Overloading::CombiningClass->DOES($role),
        "Overloading::CombiningClass does $role role"
    );
}

OverloadingTests::test_overloading_for_package($_) for qw(
    Overloading::RoleWithOverloads
    Overloading::CombiningClass
);

OverloadingTests::test_no_overloading_for_package(
    'Overloading::RoleWithoutOverloads');

OverloadingTests::test_overloading_for_package(
    'Overloading::CombiningClass');

done_testing();
