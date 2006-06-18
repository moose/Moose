#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

{
    package Base;
    use Moose::Role;

    sub method {
        "outer( " .( eval { inner() } || "" ). ")";
    };

    package SubRole;
    use Moose::Role;

    with "Base";

    eval {
        augment method => sub {
            "inner from role";
        };
    };

    ::ok( !$@, "can call augment in a role that has the parent method" );

    package ClassWithRole;
    use Moose;
    with "SubRole";

    package ClassWithoutRole;
    use Moose;
    with "Base";

    eval {
        augment method => sub {
            "inner from class";
        };
    };

    ::ok( !$@, "class can augment a method that comes from a role" );

    package UnrelatedRole;
    use Moose::Role;

    eval {
        augment method => sub {
            "inner from unrelated role";
        };
    };

    ::ok( !$@, "can call augment in a role that has does not have the parent method" );

    package ClassWithTwoRoles;
    use Moose;

    with qw/Base UnrelatedRole/;
}

foreach my $class (qw/ClassWithoutRole ClassWithRole ClassWithTwoRoles/) {
    can_ok( $class, "method" );

    ok( $class->does("Base"), "$class does Base" );

    like( $class->method, qr/^outer\( .* \)$/, "outer method invoked" );
}

is( ClassWithoutRole->method, "outer( inner from class )", "composition of class + base role" );
is( ClassWithRole->method, "outer( inner from role )", "composition of class + base role + related role" );
is( ClassWithTwoRoles->method, "outer( inner from unrelated role )", "composition of class + base role + mixin role" );

