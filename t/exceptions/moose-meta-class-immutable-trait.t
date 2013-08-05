#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception =  exception {
        package Foo;
        use Moose;

	__PACKAGE__->meta->make_immutable;
	Foo->meta->does_role;
    };

    like(
        $exception,
        qr/You must supply a role name to look for/,
        "no role_name supplied to does_role");

    isa_ok(
        $exception,
        "Moose::Exception::RoleNameRequired",
        "no role_name supplied to does_role");
}

done_testing;
