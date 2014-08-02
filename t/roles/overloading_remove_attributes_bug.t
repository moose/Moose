use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings;

use lib 't/lib';

use OverloadingTests;

{
    package MyRole;
    use Moose::Role;

    has foo => ( is => 'ro' );

    # Note ordering here. If metaclass reinitialization nukes attributes, this
    # breaks.
    with 'Overloading::RoleWithOverloads';
}

{
    package MyClass;
    use Moose;

    with 'MyRole';
}

my $object = MyClass->new( foo => 21, message => 'foo' );

OverloadingTests::test_overloading_for_object( $object, 'MyClass object' );

is( $object->foo(), 21,
    'foo attribute in MyClass is still present (from MyRole)' );

done_testing();
