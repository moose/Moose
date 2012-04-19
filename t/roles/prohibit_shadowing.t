#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Role1;

    use Moose::Role;

    sub foo { }
}

{
    package Role2;

    use Moose::Role;

    with 'Role1', { -prohibit_shadowing => 1 };

    sub foo { }
}

{
    package Class1;

    use Moose;

    ::ok(
      ::exception { with 'Role1', { -prohibit_shadowing => 1 } },
      'Shadowing prohibited role->class'
    );

    sub foo { }
}

{
    package Class2;

    use Moose;

    ::ok(
      ::exception { with 'Role2' },
      'Shadowing prohibited role->role'
    );
}

done_testing;
