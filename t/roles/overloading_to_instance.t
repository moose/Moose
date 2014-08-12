use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings;
use overload ();

use lib 't/lib';

use OverloadingTests;
use Overloading::RoleWithOverloads;

{
    package MyClass;
    use Moose;
}

my $object = MyClass->new;
Overloading::RoleWithOverloads->meta->apply($object);

OverloadingTests::test_overloading_for_package($_)
    for 'Overloading::RoleWithOverloads', ref $object;

$object->message('foo');

OverloadingTests::test_overloading_for_object(
    $object,
    'object with Overloading::RoleWithOverloads applied to instance'
);

done_testing();
