#!/usr/bin/env perl
use strict;
use Test::More;

BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
    plan tests => 1;
}

{

    package Role;
    use Moose::Role;

    has value => (
        is      => 'rw',
        clearer => 'clear_value',
    );

    after clear_value => sub { };
}
{

    package Class;
    use Moose;

    with 'Role';
    has '+value' => ( isa => q[Str] );
}

stderr_unlike(sub { Class->new; },
            qr/^You are overwriting a locally defined method \(get_a\) with an accessor/, 'reader overriding gives proper warning');
