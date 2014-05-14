use strict;
use warnings;

use Test::More;
use Test::Requires 'Algorithm::C3'; # skip all if not installed

use Class::MOP;

use lib 't/cmop/lib';
use C3MethodDispatchOrder;

{
    package Diamond_A;
    use metaclass 'C3MethodDispatchOrder';

    sub hello { 'Diamond_A::hello' }

    package Diamond_B;
    use metaclass 'C3MethodDispatchOrder';
    __PACKAGE__->meta->superclasses('Diamond_A');

    package Diamond_C;
    use metaclass 'C3MethodDispatchOrder';
    __PACKAGE__->meta->superclasses('Diamond_A');

    sub hello { 'Diamond_C::hello' }

    package Diamond_D;
    use metaclass 'C3MethodDispatchOrder';
    __PACKAGE__->meta->superclasses('Diamond_B', 'Diamond_C');
}

is_deeply(
    [ Diamond_D->meta->class_precedence_list ],
    [ qw(Diamond_D Diamond_B Diamond_C Diamond_A) ],
    '... got the right MRO for Diamond_D');

is(Diamond_D->hello, 'Diamond_C::hello', '... got the right dispatch order');
is(Diamond_D->can('hello')->(), 'Diamond_C::hello', '... can(method) resolved itself as expected');

done_testing;
