use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings;
use overload ();

use lib 't/lib';

use OverloadingTests;
use Overloading::ClassWithOneRole;

ok(
    Overloading::ClassWithOneRole->DOES('Overloading::RoleWithOverloads'),
    'Overloading::ClassWithOneRole consumed Overloading::RoleWithOverloads',
);

OverloadingTests::test_overloading_for_package($_) for qw(
    Overloading::RoleWithOverloads
    Overloading::ClassWithOneRole
);

OverloadingTests::test_overloading_for_object(
    'Overloading::ClassWithOneRole');

{
    package Role1;
    use Moose::Role;
    use overload
        q{""}    => '_role1_stringify',
        q{+}     => '_role1_plus',
        fallback => 0;
    sub _role1_stringify {__PACKAGE__}
    sub _role1_plus      {42}
}

{
    package Class1;
    use Moose;
    use overload
        q{""}    => '_class1_stringify',
        fallback => 1;
    with 'Role1';
    sub _class1_stringify {__PACKAGE__}
}

is(
    Class1->meta->get_overload_fallback_value,
    1,
    'fallback setting for class overrides setting in composed role'
);

is(
    Class1->new . q{},
    'Class1',
    'overload method for class overrides method in composed role'
);

my $overload = Class1->meta->get_overloaded_operator(q{+});
is(
    $overload->original_overload->associated_metaclass->name,
    'Role1',
    '+ overloading for Class1 originally came from Role1'
);

done_testing();
