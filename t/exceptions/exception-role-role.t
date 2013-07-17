#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

{
    {
        package DoesRoleRole;
        use Moose;
        extends 'Moose::Exception';
        with 'Moose::Exception::Role::Role';
    }

    my $exception = exception {
        my $doesRoleRole = DoesRoleRole->new;
    };

    like(
        $exception,
        qr/\QYou need to give role or role_name or both/,
        "please give either role or role_name");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherRoleNorRoleNameIsGiven",
        "please give either role or role_name");

    {
        package JustATestRole;
        use Moose::Role;
    }

    $exception = DoesRoleRole->new( role => JustATestRole->meta );

    ok( !$exception->is_role_name_set, "role_name is not set");

    is(
        $exception->role->name,
        "JustATestRole",
        "you have given role");

    is(
        $exception->role_name,
        "JustATestRole",
        "you have given role");

    $exception = DoesRoleRole->new( role_name => "JustATestRole" );

    ok( !$exception->is_role_set, "role is not set");

    is(
        $exception->role_name,
        "JustATestRole",
        "you have given role");

    is(
        $exception->role->name,
        "JustATestRole",
        "you have given role");

    $exception = DoesRoleRole->new( role_name => "JustATestRole",
                                    role      => JustATestRole->meta
                                  );

    is(
        $exception->role_name,
        "JustATestRole",
        "you have given both, role & role_name");

    is(
        $exception->role->name,
        "JustATestRole",
        "you have given both, role & role_name");

    $exception = exception {
        DoesRoleRole->new( role_name => "Foo",
                           role      => JustATestRole->meta,
                         );
    };

    like(
        $exception,
        qr/\Qrole_name (Foo) does not match role->name (JustATestRole)/,
        "you have given role_name as 'Foo' and role->name as 'JustATestRole'");

    isa_ok(
        $exception,
        "Moose::Exception::RoleNamesDoNotMatch",
        "you have given role_name as 'Foo' and role->name as 'JustATestRole'");

    is(
        $exception->role_name,
        "Foo",
        "you have given role_name as 'Foo' and role->name as 'JustATestRole'");

    is(
        $exception->role->name,
        "JustATestRole",
        "you have given role_name as 'Foo' and role->name as 'JustATestRole'");
}

done_testing;