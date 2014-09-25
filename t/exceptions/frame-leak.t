use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Requires 'Test::Memory::Cycle';

BEGIN {
    plan skip_all => 'Leak tests fail under Devel::Cover' if $INC{'Devel/Cover.pm'};
}

{
    package Foo;
    use Moose;
    has myattr => ( is => 'ro', required => 1 );
}

memory_cycle_ok(
    exception { Foo->new() },
    'exception objects do not leak arguments into Devel::StackTrace objects',
);

done_testing;
