use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Moose::Util');
}

{
    package Moosey::Class;
    use Moose;
}
{
    package Moosey::Role;
    use Moose::Role;
}
{
    package Other;
}
{
    package Moosey::Composed;
    use Moose;
    with 'Moosey::Role';
}

use Moose::Util 'is_role';

{
    my $class = Moosey::Class->new;
    my $composed = Moosey::Composed->new;

    ok(!is_role('Moosey::Class'), 'a moose class is not a role');
    ok(is_role('Moosey::Role'), 'a moose role is a role');
    ok(!is_role('Other'), 'something else is not a role');
    ok(!is_role('DoesNotExist'), 'non-existent namespace is not a role');
    ok(!is_role('Moosey::Composed'), 'a moose class that composes a role is not a role');

    ok(!is_role($class), 'instantiated moose object is not a role');
    ok(!is_role($composed), 'instantiated moose object that does a role is not a role');
}

done_testing;
