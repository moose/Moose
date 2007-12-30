#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1; #skip_all => "provisional test";
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

{
    # no conflicts, this doesn't actually test the new behavior, it's just an example

    lives_ok {
        package Role::A;
        use Moose::Role;

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(bar) };
    } "define role A";

    lives_ok {
        package Role::B;
        use Moose::Role;

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(xxy) };
    } "define role B";

    lives_ok {
        package Role::C;
        use Moose::Role;

        with qw(Role::A Role::B); # conflict between 'foo's here

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(foo zot) };
    } "define role C";

    lives_ok {
        package Class::A;
        use Moose;

        with qw(Role::C);

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(zot) };
    } "define class A";

    can_ok( Class::A->new, qw(foo bar xxy zot) );

    is( eval { Class::A->new->foo }, "Role::C::foo", "foo" );
    is( eval { Class::A->new->zot }, "Class::A::zot", "zot" );
    is( eval { Class::A->new->bar }, "Role::A::bar", "bar" );
    is( eval { Class::A->new->xxy }, "Role::B::xxy", "xxy" );

}

{
    # conflict resolved by role, same result as prev

    lives_ok {
        package Role::D;
        use Moose::Role;

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(foo bar) };
    } "define role Role::D";

    lives_ok {
        package Role::E;
        use Moose::Role;

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(foo xxy) };
    } "define role Role::E";

    lives_ok {
        package Role::F;
        use Moose::Role;

        with qw(Role::D Role::E); # conflict between 'foo's here

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(foo zot) };
    } "define role Role::F";

    lives_ok {
        package Class::B;
        use Moose;

        with qw(Role::F);

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(zot) };
    } "define class Class::B";

    can_ok( Class::B->new, qw(foo bar xxy zot) );

    is( eval { Class::B->new->foo }, "Role::F::foo", "foo" );
    is( eval { Class::B->new->zot }, "Class::B::zot", "zot" );
    is( eval { Class::B->new->bar }, "Role::D::bar", "bar" );
    is( eval { Class::B->new->xxy }, "Role::E::xxy", "xxy" );

}

{
    # conflict propagation

    lives_ok {
        package Role::H;
        use Moose::Role;

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(foo bar) };
    } "define role Role::H";

    lives_ok {
        package Role::J;
        use Moose::Role;

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(foo xxy) };
    } "define role Role::J";

    lives_ok {
        package Role::I;
        use Moose::Role;

        with qw(Role::J Role::H); # conflict between 'foo's here

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(zot) };
    } "define role Role::I";

    throws_ok {
        package Class::C;
        use Moose;

        with qw(Role::I);

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(zot) };
    } qr/requires.*'foo'/, "defining class Class::C fails";

    lives_ok {
        package Class::E;
        use Moose;

        with qw(Role::I);

        use constant;
        BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(foo zot) };
    } "resolved with method";

    # fix these later ...
    TODO: {
          local $TODO = "TODO: add support for attribute methods fufilling reqs";

        lives_ok {
            package Class::D;
            use Moose;

            has foo => ( default => __PACKAGE__ . "::foo", is => "rw" );

            use constant;
            BEGIN { constant->import($_ => __PACKAGE__ . "::$_") for qw(zot) };

            with qw(Role::I);
        } "resolved with attr";

        can_ok( Class::D->new, qw(foo bar xxy zot) );
        is( eval { Class::D->new->bar }, "Role::H::bar", "bar" );
        is( eval { Class::D->new->xxy }, "Role::I::xxy", "xxy" );
    }

    is( eval { Class::D->new->foo }, "Class::D::foo", "foo" );
    is( eval { Class::D->new->zot }, "Class::D::zot", "zot" );

    can_ok( Class::E->new, qw(foo bar xxy zot) );

    is( eval { Class::E->new->foo }, "Class::E::foo", "foo" );
    is( eval { Class::E->new->zot }, "Class::E::zot", "zot" );
    is( eval { Class::E->new->bar }, "Role::H::bar", "bar" );
    is( eval { Class::E->new->xxy }, "Role::J::xxy", "xxy" );

}

