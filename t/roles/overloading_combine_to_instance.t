use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings;
use overload ();

use lib 't/lib';

use OverloadingTests;
use Overloading::RoleWithOverloads;
use Overloading::RoleWithoutOverloads;

{
    package MyClass;
    use Moose;
}

my $object = MyClass->new;

Moose::Meta::Role->combine(
    [ 'Overloading::RoleWithOverloads'    => undef ],
    [ 'Overloading::RoleWithoutOverloads' => undef ],
)->apply($object);

OverloadingTests::test_overloading_for_package($_)
    for 'Overloading::RoleWithOverloads', ref $object;

OverloadingTests::test_no_overloading_for_package(
    'Overloading::RoleWithoutOverloads');

$object->message('foo');

OverloadingTests::test_overloading_for_object(
    $object,
    'object with Overloading::RoleWithOverloads and Overloading::RoleWithoutOverloads combined and applied to instance'
);

done_testing();
