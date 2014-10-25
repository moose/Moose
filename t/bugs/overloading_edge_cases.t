use strict;
use warnings;

use Test::More;

{
    package Role::Overloads;
    use Moose::Role;
    use overload q{""} => 'as_string';
    requires 'as_string';
}

{
    package Class::Overloads;
    use Moose;
    with 'Role::Overloads';
    sub as_string { 'foo' }
}

is(
    Class::Overloads->new() . q{}, 'foo',
    'Class::Overloads overloads stringification with overloading defined in role and method defined in class'
);

{
    package Parent::NoOverloads;
    use Moose;
    sub name { ref $_[0] }
}

{
    package Child::Overloads;
    use Moose;
    use overload q{""} => 'name';
    extends 'Parent::NoOverloads';
}

is(
    Child::Overloads->new() . q{}, 'Child::Overloads',
    'Child::Overloads overloads stringification with method inherited from parent'
);

done_testing;
